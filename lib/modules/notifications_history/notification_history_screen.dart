import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/notifications_history/widgets/notification_history_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

class NotificationHistoryScreen extends StatelessWidget {
  final List<String> items;
  late FinanceService financeService;

  NotificationHistoryScreen({
    Key? key,
    required this.items
  }) : super(key: key){
    financeService = FinanceService.getInstance(
      SqliteService().database.monthDao,
      SqliteService().database.movementValueDao,
      SqliteService().database.fixedMovementDao,
    );
  }

  List<_TitleValue> _parseItems() {
    return items.map((str) {
      final parts = str.split(' - ');
      final title = parts.isNotEmpty ? parts[0] : '';
      final value = (parts.length > 1) ? double.tryParse(parts[1].replaceAll(',', '.')) ?? 0.0 : 0.0;
      return _TitleValue(title: title, value: value);
    }).toList();
  }

  Future<void> _onSave(MovementValue movementValue) async {
    MovementValueDao dao = SqliteService().database.movementValueDao;

    await dao.insertMovementValue(movementValue);
  }

  @override
  Widget build(BuildContext context) {
    final parsedItems = _parseItems();
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Card(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(90),
            ),
          ),
          child: ListView.separated(
            itemCount: parsedItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = parsedItems[index];
              return NotificationWidget(item.title, item.value, context, financeService.currentMonth?.id ?? -1, _onSave);
            },
          ),
        ),
      ),
    );
  }
}

class _TitleValue {
  final String title;
  final double value;
  _TitleValue({required this.title, required this.value});
}
