import 'package:cashly/data/models/month.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/settings.dart/widgets/import_from_gastoscopio.dart';
import 'package:cashly/modules/settings.dart/widgets/logs_screen.dart';

class DeveloperOptionsWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onImportSuccess;

  const DeveloperOptionsWidget({super.key, this.onImportSuccess});

  @override
  State<DeveloperOptionsWidget> createState() => _DeveloperOptionsWidgetState();
}

class _DeveloperOptionsWidgetState extends State<DeveloperOptionsWidget> {
  void _showLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogsScreen()),
    );
  }

  bool _isExpanded = false;
  bool _isClearing = false;

  Future<void> _clearDatabase() async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.deleteDatabase),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.dbDeleteWarning,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.dbDeleteList1),
              Text(AppLocalizations.of(context)!.dbDeleteList2),
              Text(AppLocalizations.of(context)!.dbDeleteList3),
              Text(AppLocalizations.of(context)!.dbDeleteList4),
              SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.dbDeleteUnrecoverable,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.dbDeleteRecomendation,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.deleteAll),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
    });
    try {
      // Limpiar todas las tablas usando los DAOs disponibles
      final sqliteService = SqliteService();
      await sqliteService.initializeDatabase();

      final db = sqliteService.db;

      // Limpiar tabla de movimientos
      await db.movementValueDao.deleteAllMovements();

      // Limpiar tabla de movimientos fijos
      await db.fixedMovementDao
          .deleteAllFixedMovements(); // Limpiar tabla de meses
      await db.monthDao.deleteAllMonths();

      await db.monthDao.insertMonth(
        Month(DateTime.now().month, DateTime.now().year),
      );

      if (mounted) {
        // Toast de éxito
        Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.dbDeletedSuccesfully,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 4,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Mostrar diálogo informativo
        _showLogs();
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.dbDeleted),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.deleteDatabaseSubtitle,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.dbDeleteAppRestart),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.dbDeleteAppRestartAdvice,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        // Toast de error
        Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.errorCleaningDatabase,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // SnackBar con detalles del error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.errorCleaningDatabase,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }

      LogFileService().appendLog('Error clearing database: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.error.withAlpha(15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.developer_mode,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            title: Text(
              AppLocalizations.of(context)!.developerOptions,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.developerOptionsSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de Importar JSON
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.upload_file,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.importFromJson,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.importFromJsonSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ImportFromGastoscopioScreen(
                          onImportSuccess:
                              widget.onImportSuccess ?? (result) {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sección de Ver Logs
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ver Logs',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Visualiza los logs de la aplicación para depuración.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LogsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('Ver Logs'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sección de Limpiar Base de Datos
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withAlpha(100),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.delete_forever,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.deleteDatabase,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.deleteDatabaseSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withAlpha(100),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.error,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.dbDeleteRecomendation,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isClearing ? null : _clearDatabase,
                            icon: _isClearing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Loading(context),
                                  )
                                : const Icon(Icons.delete_forever),
                            label: Text(
                              _isClearing
                                  ? AppLocalizations.of(context)!.cleaning
                                  : AppLocalizations.of(context)!.cleanAllData,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onError,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
