import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/smart_alerts_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SmartAlertsBanner extends StatefulWidget {
  const SmartAlertsBanner({super.key});

  @override
  State<SmartAlertsBanner> createState() => _SmartAlertsBannerState();
}

class _SmartAlertsBannerState extends State<SmartAlertsBanner> {
  List<SmartAlert> _alerts = [];
  bool _isLoading = true;
  String _currency = '€';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final alerts = await SmartAlertsService().getAlerts(now.month, now.year);
    final currency = await SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency);
    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _currency = currency ?? '€';
      _isLoading = false;
    });
  }

  AlertSeverity _topSeverity() {
    if (_alerts.any((a) => a.severity == AlertSeverity.critical)) {
      return AlertSeverity.critical;
    }
    if (_alerts.any((a) => a.severity == AlertSeverity.warning)) {
      return AlertSeverity.warning;
    }
    return AlertSeverity.info;
  }

  Color _colorForSeverity(BuildContext context, AlertSeverity s) {
    final theme = Theme.of(context);
    switch (s) {
      case AlertSeverity.critical:
        return theme.colorScheme.error;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return theme.colorScheme.primary;
    }
  }

  IconData _iconForSeverity(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return Icons.error_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber_outlined;
      case AlertSeverity.info:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _alerts.isEmpty) return const SizedBox.shrink();

    final topSeverity = _topSeverity();
    final color = _colorForSeverity(context, topSeverity);
    final icon = _iconForSeverity(topSeverity);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      color: color.withAlpha(25),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(100)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.smartAlertsTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.smartAlertsSummary(_alerts.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SmartAlertsSheet(alerts: _alerts, currency: _currency),
    );
  }
}

class SmartAlertsSheet extends StatelessWidget {
  final List<SmartAlert> alerts;
  final String currency;

  const SmartAlertsSheet({
    super.key,
    required this.alerts,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    localizations.smartAlertsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _AlertTile(
                  alert: alerts[i],
                  currency: currency,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final SmartAlert alert;
  final String currency;

  const _AlertTile({required this.alert, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    Color color;
    IconData icon;
    String title;
    String subtitle;

    switch (alert.kind) {
      case AlertKind.budgetExceeded:
        color = theme.colorScheme.error;
        icon = Icons.error_outline;
        title = localizations.alertBudgetExceededTitle(alert.category);
        subtitle = localizations.alertBudgetExceededBody(
          alert.currentValue.toStringAsFixed(2) + currency,
          alert.referenceValue.toStringAsFixed(2) + currency,
          alert.delta.toStringAsFixed(2) + currency,
        );
        break;
      case AlertKind.budgetNearLimit:
        color = Colors.orange;
        icon = Icons.warning_amber_outlined;
        final pct = (alert.ratio * 100).round();
        title = localizations.alertBudgetNearTitle(alert.category);
        subtitle = localizations.alertBudgetNearBody(
          pct.toString(),
          alert.currentValue.toStringAsFixed(2) + currency,
          alert.referenceValue.toStringAsFixed(2) + currency,
        );
        break;
      case AlertKind.spendingSpike:
        color = theme.colorScheme.primary;
        icon = Icons.trending_up;
        final pct = alert.referenceValue > 0
            ? ((alert.currentValue - alert.referenceValue) /
                    alert.referenceValue *
                    100)
                .round()
            : 0;
        title = localizations.alertSpendingSpikeTitle(alert.category);
        subtitle = localizations.alertSpendingSpikeBody(
          '+$pct%',
          alert.referenceValue.toStringAsFixed(2) + currency,
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
