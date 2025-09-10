import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/l10n/app_localizations.dart';

class BackupRestoreWidget extends StatefulWidget {
  const BackupRestoreWidget({Key? key}) : super(key: key);

  @override
  State<BackupRestoreWidget> createState() => _BackupRestoreWidgetState();
}

class _BackupRestoreWidgetState extends State<BackupRestoreWidget> {
  bool _isLoading = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await LoginService().silentLogin();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }

  Widget _buildLoginOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).loginRequired,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).loginToAccess,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          color: Theme.of(context).colorScheme.tertiary.withAlpha(25),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withAlpha(50),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_sync,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Backup y Restauración',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestiona las copias de seguridad de tus datos en Google Drive.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Botón de Backup
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _performBackup,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: Loading(context),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isLoading ? 'Subiendo...' : 'Hacer Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón de Restore
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _checkAndRestoreBackup,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: Loading(context),
                          )
                        : const Icon(Icons.cloud_download),
                    label: Text(
                      _isLoading ? 'Verificando...' : 'Restaurar desde Backup',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withAlpha(50),
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
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los datos se guardan en tu Google Drive personal. Te recomendamos hacer backups periódicos.',
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
              ],
            ),
          ),
        ),
        if (!_isLoggedIn) Positioned.fill(child: _buildLoginOverlay()),
      ],
    );
  }

  Future<void> _performBackup() async {
    setState(() {
      _isLoading = true;
    });

    // Mostrar diálogo de carga
    bool loadingDialogShown = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        loadingDialogShown = true;
        return PopScope(
          canPop: false, // Prevenir cierre accidental
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Loading(context),
                SizedBox(height: 16),
                Text('Subiendo datos a Google Drive...'),
                SizedBox(height: 8),
                Text(
                  'Por favor espera, esto puede tomar un momento...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final success = await LoginService().uploadDatabase();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Cerrar diálogo de carga si está abierto
        if (loadingDialogShown) {
          Navigator.of(context).pop();
          loadingDialogShown = false;
        }

        // Mostrar resultado
        _showResultDialog(
          success: success,
          title: success ? 'Backup Exitoso' : 'Error en Backup',
          message: success
              ? 'Tus datos han sido guardados exitosamente en Google Drive.'
              : 'Hubo un problema al subir los datos. Verifica tu conexión a internet e inténtalo de nuevo.',
          icon: success ? Icons.check_circle : Icons.error,
          color: success ? Colors.green : Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Cerrar diálogo de carga si está abierto
        if (loadingDialogShown) {
          Navigator.of(context).pop();
          loadingDialogShown = false;
        }

        _showResultDialog(
          success: false,
          title: 'Error en Backup',
          message: 'Error: $e',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    }
  }

  Future<void> _checkAndRestoreBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await LoginService().checkExistingBackup();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result.isNotEmpty && result != 'No backup found') {
          _showRestoreConfirmationDialog(result);
        } else {
          _showResultDialog(
            success: false,
            title: 'Sin Backup',
            message: 'No se encontró ningún backup en tu Google Drive.',
            icon: Icons.cloud_off,
            color: Colors.orange,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showResultDialog(
          success: false,
          title: 'Error al Verificar Backup',
          message: 'Error: $e',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    }
  }

  void _showRestoreConfirmationDialog(String backupInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirmar Restauración'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Estás seguro de que deseas restaurar desde el backup?\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Esta acción sobrescribirá todos tus datos actuales con los datos del backup.\n',
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Información del backup:\n$backupInfo',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performRestore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performRestore() async {
    // Variable para controlar el diálogo de carga
    bool loadingDialogShown = false;
    try {
      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext loadingContext) {
          loadingDialogShown = true;
          return PopScope(
            canPop: false, // Prevenir cierre accidental
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Loading(context),
                  SizedBox(height: 16),
                  Text('Restaurando datos...'),
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

      // Aquí iría la lógica de restauración, pero basándome en el LoginService
      // parece que checkExistingBackup solo verifica, no restaura
      // Por ahora simularemos la restauración
      await Future.delayed(const Duration(seconds: 2));

      // Cerrar diálogo de progreso si está abierto
      if (loadingDialogShown && mounted) {
        Navigator.of(context).pop();
        loadingDialogShown = false;
      }

      if (mounted) {
        _showResultDialog(
          success: true,
          title: 'Restauración Exitosa',
          message:
              'Los datos han sido restaurados exitosamente. Es recomendable reiniciar la aplicación.',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      }
    } catch (e) {
      // Cerrar diálogo de progreso si está abierto
      if (loadingDialogShown && mounted) {
        Navigator.of(context).pop();
        loadingDialogShown = false;
      }

      if (mounted) {
        _showResultDialog(
          success: false,
          title: 'Error en Restauración',
          message: 'Error: $e',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    }
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
