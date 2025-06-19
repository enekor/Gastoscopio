import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/settings.dart/widgets/apikey-generator.dart';
import 'package:cashly/modules/settings.dart/widgets/import_from_gastoscopio.dart';
import 'package:cashly/modules/settings.dart/widgets/backup_restore_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:svg_flutter/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentCurrency = '€';
  bool _isSvg = false;
  int _r = 255;
  int _g = 255;
  int _b = 255;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _handleImportSuccess(Map<String, dynamic>? result) async {
    if (result == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('No hay datos para importar'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Aceptar'),
              ),
            ],
          );
        },
      );
      return;
    }
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Importando datos...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Guardando ${result['Movements'].length} movimientos'),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Ok'),
                ),
              ],
            ),
          );
        },
      );

      // Import months first
      for (Month month in result['Months']) {
        await SqliteService().db.monthDao.insertMonth(month);
      }

      // Then import movements
      for (MovementValue movement in result['Movements']) {
        await SqliteService().db.movementValueDao.insertMovementValue(movement);
      }

      // Finalmente, importa los movimientos fijos si existen
      if (result.containsKey('FixedMovements')) {
        for (FixedMovement fixedMovement in result['FixedMovements']) {
          await SqliteService().db.fixedMovementDao.insertFixedMovement(
            fixedMovement,
          );
        }
      }

      // Subir a la copia de seguridad
      await LoginService().uploadDatabase();

      // Pop the progress dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los datos se han importado correctamente'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Pop the progress dialog only if we're showing it
      try {
        Navigator.pop(context);
      } catch (popError) {
        // Ignore pop errors
      }

      // Show error dialog with more specific messages
      String errorMessage = 'Ocurrió un error al guardar los datos';
      if (e.toString().contains('database')) {
        errorMessage =
            'Error al inicializar la base de datos. Por favor, intenta de nuevo.';
      } else if (e.toString().contains('insert')) {
        errorMessage =
            'Error al guardar los datos. Verifica que el formato del archivo sea correcto.';
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error al importar'),
            content: Text('$errorMessage\n\nDetalles: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Continuar sin importar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Intentar de nuevo'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _loadData() async {
    final currency = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.currency,
    );
    if (currency != null && mounted) {
      setState(() {
        _currentCurrency = currency;
      });
    }

    final isSvg = await SharedPreferencesService().getBoolValue(
      SharedPreferencesKeys.isSvgAvatar,
    );
    if (isSvg != null && mounted) {
      setState(() {
        _isSvg = isSvg;
      });
    }

    final avatarColor = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.avatarColor,
    );
    if (avatarColor != null && mounted) {
      setState(() {
        _r = int.tryParse(avatarColor.split(",")[0]) ?? 255;
        _g = int.tryParse(avatarColor.split(",")[1]) ?? 255;
        _b = int.tryParse(avatarColor.split(",")[2]) ?? 255;
      });
    }
  }

  Future<void> _saveCurrency(String currency) async {
    await SharedPreferencesService().setStringValue(
      SharedPreferencesKeys.currency,
      currency,
    );
    if (mounted) {
      setState(() {
        _currentCurrency = currency;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moneda actualizada correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveLogo() async {
    await SharedPreferencesService().setBoolValue(
      SharedPreferencesKeys.isSvgAvatar,
      _isSvg,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo actualizado correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveAvatarColor(int r, int g, int b) async {
    await SharedPreferencesService().setStringValue(
      SharedPreferencesKeys.avatarColor,
      '$r,$g,$b',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Color de avatar actualizado correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: GoogleFonts.pacifico(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildSectionHeader(
                context,
                'Personalización',
                'Configura tu experiencia en la aplicación.',
                Icons.palette_outlined,
              ),
              const SizedBox(height: 20),

              // Currency Card
              _buildCurrencyCard(context),
              const SizedBox(height: 20),

              // Logo Card
              _buildLogoCard(context),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              // API Section
              _buildSectionHeader(
                context,
                'Inteligencia Artificial',
                'Configuración para funciones avanzadas con IA.',
                Icons.smart_toy_outlined,
              ),
              const SizedBox(height: 20),

              // API Key Card
              const ApiKeyGenerator(),

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              _buildSectionHeader(
                context,
                'Gestión de Datos',
                'Importar y gestionar tus datos financieros.',
                Icons.storage_outlined,
              ),
              const SizedBox(height: 20),
              ImportFromGastoscopioScreen(
                onImportSuccess: _handleImportSuccess,
              ),
              const SizedBox(height: 20),

              // Backup & Restore Section
              const BackupRestoreWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
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
                  Icons.currency_exchange,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Moneda Preferida',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona la moneda que se mostrará en toda la aplicación.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(100),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _currentCurrency,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: '€', child: Text('Euro (€)')),
                  DropdownMenuItem(
                    value: '\$',
                    child: Text('Dólar Estadounidense (\$)'),
                  ),
                  DropdownMenuItem(
                    value: '£',
                    child: Text('Libra Esterlina (£)'),
                  ),
                  DropdownMenuItem(value: '¥', child: Text('Yen Japonés (¥)')),
                  DropdownMenuItem(
                    value: 'CHF',
                    child: Text('Franco Suizo (CHF)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _saveCurrency(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
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
                  Icons.image_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personalización del Logo.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Elige entre PNG estático o SVG personalizable con color.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // PNG Option
                Expanded(
                  child: _buildLogoOption(
                    context,
                    isPng: true,
                    isSelected: !_isSvg,
                    onTap: () {
                      setState(() {
                        _isSvg = false;
                      });
                      _saveLogo();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // SVG Option
                Expanded(
                  child: _buildLogoOption(
                    context,
                    isPng: false,
                    isSelected: _isSvg,
                    onTap: () {
                      setState(() {
                        _isSvg = true;
                      });
                      _saveLogo();
                    },
                  ),
                ),
              ],
            ),
            if (_isSvg) ...[
              const SizedBox(height: 20),
              Divider(
                color: Theme.of(context).colorScheme.outline.withAlpha(50),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.color_lens_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Color del Logo SVG.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color.fromARGB(255, _r, _g, _b),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: _getContrastColor(
                            Color.fromARGB(255, _r, _g, _b),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoOption(
    BuildContext context, {
    required bool isPng,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withAlpha(100),
            width: isSelected ? 2 : 1,
          ),
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withAlpha(25)
                  : Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color:
                    !isPng
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Colors.transparent,
              ),
              child: Center(
                child:
                    isPng
                        ? Image.asset(
                          'assets/logo.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        )
                        : SvgPicture.asset(
                          'assets/logo.svg',
                          width: 40,
                          height: 40,
                          colorFilter: ColorFilter.mode(
                            Color.fromARGB(255, _r, _g, _b),
                            BlendMode.srcIn,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPng ? 'PNG' : 'SVG',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPng ? 'Estático' : 'Personalizable',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Selecciona un Color'),
            ],
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Color.fromARGB(255, _r, _g, _b),
              onColorChanged: (Color color) {
                setState(() {
                  _r = color.red;
                  _g = color.green;
                  _b = color.blue;
                });
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _saveAvatarColor(_r, _g, _b);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate relative luminance
    double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
