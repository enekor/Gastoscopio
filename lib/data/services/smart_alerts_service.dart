import 'package:cashly/data/services/budget_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';

enum AlertSeverity { info, warning, critical }

enum AlertKind {
  budgetExceeded,
  budgetNearLimit,
  spendingSpike,
}

class SmartAlert {
  final AlertKind kind;
  final AlertSeverity severity;
  final String category;
  final double currentValue;
  final double referenceValue;

  SmartAlert({
    required this.kind,
    required this.severity,
    required this.category,
    required this.currentValue,
    required this.referenceValue,
  });

  /// Excess amount for exceeded alerts, or delta over reference for spikes.
  double get delta => currentValue - referenceValue;

  /// Progress ratio (useful for near-limit/exceeded).
  double get ratio =>
      referenceValue > 0 ? currentValue / referenceValue : 0;
}

class SmartAlertsService {
  static final SmartAlertsService _instance =
      SmartAlertsService._internal();
  factory SmartAlertsService() => _instance;
  SmartAlertsService._internal();

  /// Returns current alerts for the given month/year. Computes:
  ///  - Budget exceeded (critical)
  ///  - Budget near limit, >=80% (warning)
  ///  - Category spending spike: current > 150% of average over previous
  ///    up to 3 months where that category had any spending (info)
  Future<List<SmartAlert>> getAlerts(int month, int year) async {
    final db = SqliteService().db;
    final budgetService =
        BudgetService(db.categoryBudgetDao, db.movementValueDao);

    final monthRow = await db.monthDao.findMonthByMonthAndYear(month, year);
    if (monthRow == null) return [];

    final alerts = <SmartAlert>[];

    // Budget alerts
    final spendList = await budgetService.getSpendForMonth(monthRow.id!);
    for (final s in spendList) {
      if (!s.hasLimit) continue;
      if (s.isExceeded) {
        alerts.add(SmartAlert(
          kind: AlertKind.budgetExceeded,
          severity: AlertSeverity.critical,
          category: s.category,
          currentValue: s.spent,
          referenceValue: s.limit!,
        ));
      } else if (s.isNearLimit) {
        alerts.add(SmartAlert(
          kind: AlertKind.budgetNearLimit,
          severity: AlertSeverity.warning,
          category: s.category,
          currentValue: s.spent,
          referenceValue: s.limit!,
        ));
      }
    }

    // Spending spike alerts — compare current-month category spend to average
    // of same category in up to 3 previous months where that category was
    // spent on at all.
    final currentByCategory = <String, double>{};
    final movements =
        await db.movementValueDao.findMovementValuesByMonthIdAndType(
      monthRow.id!,
      true,
    );
    for (final m in movements) {
      final c = m.category;
      if (c == null || c.isEmpty) continue;
      currentByCategory[c] = (currentByCategory[c] ?? 0) + m.amount;
    }

    final historicalByCategory = <String, List<double>>{};
    int m = month;
    int y = year;
    for (int back = 0; back < 3; back++) {
      if (m == 1) {
        m = 12;
        y -= 1;
      } else {
        m -= 1;
      }
      final row = await db.monthDao.findMonthByMonthAndYear(m, y);
      if (row == null) continue;
      final items = await db.movementValueDao
          .findMovementValuesByMonthIdAndType(row.id!, true);
      final sums = <String, double>{};
      for (final mv in items) {
        final c = mv.category;
        if (c == null || c.isEmpty) continue;
        sums[c] = (sums[c] ?? 0) + mv.amount;
      }
      for (final entry in sums.entries) {
        historicalByCategory
            .putIfAbsent(entry.key, () => [])
            .add(entry.value);
      }
    }

    for (final entry in currentByCategory.entries) {
      // Skip categories already flagged for budget (would be noisy)
      if (alerts.any((a) => a.category == entry.key)) continue;

      final hist = historicalByCategory[entry.key];
      if (hist == null || hist.isEmpty) continue;
      final avg = hist.reduce((a, b) => a + b) / hist.length;
      if (avg < 10) continue; // ignore tiny-amount noise
      if (entry.value >= avg * 1.5 && entry.value - avg >= 20) {
        alerts.add(SmartAlert(
          kind: AlertKind.spendingSpike,
          severity: AlertSeverity.info,
          category: entry.key,
          currentValue: entry.value,
          referenceValue: avg,
        ));
      }
    }

    // Sort: critical first, then warning, then info
    alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index) * -1);
    return alerts;
  }
}
