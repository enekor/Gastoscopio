import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashly/data/services/login_service.dart';

class BackupReminderService {
  static const String _lastBackupReminderKey = 'last_backup_reminder';
  static const int _reminderIntervalDays = 15;

  /// Verifica si debe mostrar el recordatorio de backup y lo muestra si es necesario
  static Future<void> checkAndShowBackupReminder(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastReminderTime = prefs.getInt(_lastBackupReminderKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final daysSinceLastReminder =
        (currentTime - lastReminderTime) / (1000 * 60 * 60 * 24);

    if (daysSinceLastReminder >= _reminderIntervalDays) {
      await _showBackupReminderDialog(context);
      await prefs.setInt(_lastBackupReminderKey, currentTime);
    }
  }

  /// Muestra el diálogo de recordatorio de backup
  static Future<void> _showBackupReminderDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.blue),
              SizedBox(width: 8),
              Text('Backup de datos'),
            ],
          ),
          content: const Text(
            '¿Deseas realizar una copia de seguridad de tus datos en Google Drive?\n\n'
            'Es recomendable hacer backups periódicos para proteger tu información financiera.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ahora no'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performBackup(context);
              },
              child: const Text('Sí, hacer backup'),
            ),
          ],
        );
      },
    );
  }

  /// Realiza el backup y muestra el resultado
  static Future<void> _performBackup(BuildContext context) async {
    // Variable para controlar el diálogo de carga
    bool loadingDialogShown = false;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext loadingContext) {
          loadingDialogShown = true;
          return PopScope(
            canPop: false, // Prevenir cierre accidental
            child: const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Subiendo datos a Google Drive...'),
                  SizedBox(height: 8),
                  Text(
                    'Por favor espera...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final success = await LoginService().uploadDatabase();

      // Cerrar indicador de carga si está abierto
      if (loadingDialogShown && context.mounted) {
        Navigator.of(context).pop();
        loadingDialogShown = false;
      }

      // Mostrar resultado solo si el contexto sigue válido
      if (context.mounted) {
        await showDialog(
          context: context,
          builder:
              (BuildContext resultContext) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      success ? Icons.check_circle : Icons.error,
                      color: success ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(success ? 'Backup exitoso' : 'Error en backup'),
                  ],
                ),
                content: Text(
                  success
                      ? 'Tus datos han sido guardados exitosamente en Google Drive.'
                      : 'Hubo un problema al subir los datos. Inténtalo de nuevo más tarde.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(resultContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (loadingDialogShown && context.mounted) {
        Navigator.of(context).pop();
        loadingDialogShown = false;
      }

      // Mostrar error solo si el contexto sigue válido
      if (context.mounted) {
        await showDialog(
          context: context,
          builder:
              (BuildContext errorContext) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Error en backup'),
                  ],
                ),
                content: Text('Error: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(errorContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  /// Marca manualmente que se realizó un recordatorio (para resetear el contador)
  static Future<void> markReminderShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastBackupReminderKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
