import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/notifications_history/widgets/notification_history_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class NotificationHistoryScreen extends StatefulWidget {
  final List<String> items;

  const NotificationHistoryScreen({Key? key, required this.items})
    : super(key: key);

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  late FinanceService financeService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    financeService = FinanceService.getInstance(
      SqliteService().database.monthDao,
      SqliteService().database.movementValueDao,
      SqliteService().database.fixedMovementDao,
    );
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).notificationsEnabled),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          _showSettingsDialog();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSettingsDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).disableNotificationsTitle),
            content: Text(
              AppLocalizations.of(context).disableNotificationsMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AppSettings.openAppSettings(
                    type: AppSettingsType.notification,
                  );
                },
                child: Text(AppLocalizations.of(context).goToSettings),
              ),
            ],
          ),
    );
  }

  List<_TitleValue> _parseItems() {
    return widget.items.map((str) {
      final parts = str.split(' - ');
      final title = parts.isNotEmpty ? parts[0] : '';
      final value =
          (parts.length > 1)
              ? double.tryParse(parts[1].replaceAll(',', '.')) ?? 0.0
              : 0.0;
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
        title: Text(AppLocalizations.of(context).notificationsHistory),
        actions: [
          FutureBuilder<PermissionStatus>(
            future: Permission.notification.status,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  _isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final isGranted = snapshot.data?.isGranted ?? false;
              return IconButton(
                icon: Icon(
                  isGranted
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color:
                      isGranted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                ),
                onPressed:
                    isGranted
                        ? _showSettingsDialog
                        : _requestNotificationPermission,
                tooltip:
                    isGranted
                        ? AppLocalizations.of(context).disableNotifications
                        : AppLocalizations.of(context).enableNotifications,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondary.withAlpha(25),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).notificationPermissionRequired,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withAlpha(90),
                  ),
                ),
                child:
                    parsedItems.isEmpty
                        ? Center(
                          child: Text(
                            AppLocalizations.of(context).noNotificationsYet,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                        : ListView.separated(
                          itemCount: parsedItems.length,
                          separatorBuilder:
                              (context, index) => const Divider(
                                height: 1,
                                thickness: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                          itemBuilder: (context, index) {
                            final item = parsedItems[index];
                            return NotificationWidget(
                              item.title,
                              item.value,
                              context,
                              financeService.currentMonth?.id ?? -1,
                              _onSave,
                            );
                          },
                        ),
              ),
            ),
          ],
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
