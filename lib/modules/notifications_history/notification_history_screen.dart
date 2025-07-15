import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

class NotificationHistoryScreen extends StatelessWidget {
  final List<String> items;

  const ShowNotificationHistoryScreen({
    Key? key,
    required this.items,
    this.currency,
  }) : super(key: key);

  List<_TitleValue> _parseItems() {
    return items.map((str) {
      final parts = str.split(' - ');
      final title = parts.isNotEmpty ? parts[0] : '';
      final value = (parts.length > 1) ? double.tryParse(parts[1].replaceAll(',', '.')) ?? 0.0 : 0.0;
      return _TitleValue(title: title, value: value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final parsedItems = _parseItems();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.notifications ?? 'Notificaciones'),
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
              return ListTile(
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  item.value.toStringAsFixed(2),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
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
