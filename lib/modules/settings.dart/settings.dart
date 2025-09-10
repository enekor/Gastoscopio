import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/locale_service.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/settings.dart/widgets/apikey-generator.dart';
import 'package:cashly/modules/settings.dart/widgets/developer_options_widget.dart';
import 'package:cashly/modules/settings.dart/widgets/backup_restore_widget.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:svg_flutter/svg.dart';
import 'package:cashly/modules/settings.dart/widgets/security_settings_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentCurrency = '€';
  bool _isSvg = false;
  bool _isOpaqueBottomNav = false;
  String _selectedLanguage = 'system';
  int _r = 255;
  int _g = 255;
  int _b = 255;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loginService = LoginService();
    final isLoggedIn = await loginService.silentLogin();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }

  void _handleImportSuccess(Map<String, dynamic>? result) async {
    if (result == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.error),
            content: Text(AppLocalizations.of(context)!.noDataToImport),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.accept),
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
            title: Text(AppLocalizations.of(context)!.importingData),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Loading(context),
                const SizedBox(height: 16),
                Text(
                  '${AppLocalizations.of(context)!.saving} ${result['Movements'].length} ${AppLocalizations.of(context)!.movements.toLowerCase()}',
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.ok),
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
        movement.category = movement.category?.trim();
        await SqliteService().db.movementValueDao.insertMovementValue(movement);
      } // Finalmente, importa los movimientos fijos si existen
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.dataImportedSuccessfully),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
      String errorMessage = AppLocalizations.of(context)!.errorSavingData;
      if (e.toString().contains('database')) {
        errorMessage = AppLocalizations.of(
          context,
        )!.databaseInitializationError;
      } else if (e.toString().contains('insert')) {
        errorMessage = AppLocalizations.of(context)!.dataFormatError;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.importError),
            content: Text(
              '$errorMessage\n\n${AppLocalizations.of(context)!.error}: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  AppLocalizations.of(context)!.continueWithoutImporting,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.tryAgain),
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

    final isOpaqueBottomNav = await SharedPreferencesService().getBoolValue(
      SharedPreferencesKeys.isOpaqueBottomNav,
    );
    if (isOpaqueBottomNav != null && mounted) {
      setState(() {
        _isOpaqueBottomNav = isOpaqueBottomNav;
      });
    }

    final selectedLanguage = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.selectedLanguage,
    );
    if (mounted) {
      setState(() {
        _selectedLanguage = selectedLanguage ?? 'system';
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.currencyChangedSuccessfully,
          ),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.logoChangedSuccessfully),
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.avatarColorChangedSuccessfully,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveBottomNavStyle(bool isOpaque) async {
    await SharedPreferencesService().setBoolValue(
      SharedPreferencesKeys.isOpaqueBottomNav,
      isOpaque,
    );
    if (mounted) {
      setState(() {
        _isOpaqueBottomNav = isOpaque;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOpaque
                ? AppLocalizations.of(context)!.opaqueBottomNavApplied
                : AppLocalizations.of(context)!.transparentBottomNavApplied,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveLanguageSetting(String languageCode) async {
    try {
      final localeService = LocaleService();
      await localeService.setLocale(
        languageCode == 'system' ? null : languageCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.languageChangedSuccessfully,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorChangingLanguage(e.toString()),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final loginService = LoginService();
    await loginService.signOut();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loggedOutSuccessfully),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    final loginService = LoginService();
    final success = await loginService.signIn();
    if (mounted) {
      if (success.isSuccess) {
        setState(() {
          _isLoggedIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loggedInSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loginError),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 32,
        title: Padding(
          padding: const EdgeInsets.only(top: 35.0),
          child: Text(
            AppLocalizations.of(context)!.settings,
            style: TextStyle(
              fontFamily: 'Pacifico',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
              // Account Section
              _buildSectionHeader(
                context,
                AppLocalizations.of(context).accountSection,
                AppLocalizations.of(context).accountDescription,
                Icons.account_circle_outlined,
              ),
              const SizedBox(height: 20),
              _buildAccountCard(context),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              // Personalization Section
              _buildSectionHeader(
                context,
                AppLocalizations.of(context)!.personalization,
                AppLocalizations.of(context)!.personalizationSubtitle,
                Icons.palette_outlined,
              ),
              const SizedBox(height: 20),

              // Language Card
              _buildLanguageCard(context),
              const SizedBox(height: 20),

              // Currency Card
              _buildCurrencyCard(context),
              const SizedBox(height: 20),

              // Logo Card
              _buildLogoCard(context),
              const SizedBox(height: 20),

              // Bottom Navigation Style Card
              _buildBottomNavCard(context),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              // Security Section
              _buildSectionHeader(
                context,
                AppLocalizations.of(context).security,
                AppLocalizations.of(context).securityDescription,
                Icons.security,
              ),
              const SizedBox(height: 20),
              const SecuritySettingsCard(),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              // API Section
              _buildSectionHeader(
                context,
                AppLocalizations.of(context)!.artificialIntelligence,
                AppLocalizations.of(context)!.aiDescription,
                Icons.smart_toy_outlined,
              ),
              const SizedBox(height: 20),

              // API Key Card
              const ApiKeyGenerator(), const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              // Developer Options Section
              _buildSectionHeader(
                context,
                AppLocalizations.of(context)!.backupManagement,
                AppLocalizations.of(context)!.backupDescription,
                Icons.backup_outlined,
              ),
              const SizedBox(height: 20),
              const BackupRestoreWidget(),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              DeveloperOptionsWidget(onImportSuccess: _handleImportSuccess),

              // Backup & Restore Section
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
                  AppLocalizations.of(context)!.currency,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.currencyDescription,
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
                items: [
                  DropdownMenuItem(
                    value: '€',
                    child: Text(AppLocalizations.of(context)!.euroSymbol),
                  ),
                  DropdownMenuItem(
                    value: '\$',
                    child: Text(AppLocalizations.of(context)!.dollarSymbol),
                  ),
                  DropdownMenuItem(
                    value: '£',
                    child: Text(AppLocalizations.of(context)!.poundSymbol),
                  ),
                  DropdownMenuItem(
                    value: '¥',
                    child: Text(AppLocalizations.of(context)!.yenSymbol),
                  ),
                  DropdownMenuItem(
                    value: 'CHF',
                    child: Text(AppLocalizations.of(context)!.swissFrancSymbol),
                  ),
                  DropdownMenuItem(
                    value: 'COP',
                    child: Text(
                      AppLocalizations.of(context)!.colombianPesoSymbol,
                    ),
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
                  AppLocalizations.of(context)!.logoPersonalization,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.logoDescription,
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
                    AppLocalizations.of(context)!.svgColorLabel,
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
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withAlpha(100),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
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
                color: !isPng
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.transparent,
              ),
              child: Center(
                child: isPng
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
              isPng
                  ? AppLocalizations.of(context)!.png
                  : AppLocalizations.of(context)!.svg,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPng
                  ? AppLocalizations.of(context)!.staticLabel
                  : AppLocalizations.of(context)!.customizableLabel,
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
              Text(AppLocalizations.of(context)!.selectColor),
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
                AppLocalizations.of(context)!.cancel,
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
              child: Text(AppLocalizations.of(context)!.apply),
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

  Widget _buildBottomNavCard(BuildContext context) {
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
                  Icons.navigation_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.navigationStyle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.navigationStyleDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Transparent Option
                Expanded(
                  child: _buildNavOption(
                    context,
                    isOpaque: false,
                    isSelected: !_isOpaqueBottomNav,
                    onTap: () => _saveBottomNavStyle(false),
                  ),
                ),
                const SizedBox(width: 16),
                // Opaque Option
                Expanded(
                  child: _buildNavOption(
                    context,
                    isOpaque: true,
                    isSelected: _isOpaqueBottomNav,
                    onTap: () => _saveBottomNavStyle(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavOption(
    BuildContext context, {
    required bool isOpaque,
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
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withAlpha(100),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withAlpha(25)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Stack(
                children: [
                  // Simulated screen content
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  // Simulated bottom nav
                  Positioned(
                    bottom: 4,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isOpaque
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(200)
                            : Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(60),
                        border: isOpaque
                            ? null
                            : Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(100),
                                width: 1,
                              ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(
                            Icons.home,
                            size: 12,
                            color: isOpaque
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          Icon(
                            Icons.receipt,
                            size: 12,
                            color: isOpaque
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withAlpha(150)
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(150),
                          ),
                          Icon(
                            Icons.bar_chart,
                            size: 12,
                            color: isOpaque
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withAlpha(150)
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(150),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isOpaque
                  ? AppLocalizations.of(context)!.opaqueNavigation
                  : AppLocalizations.of(context)!.transparentNavigation,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isOpaque
                  ? AppLocalizations.of(context)!.solidBackground
                  : AppLocalizations.of(context)!.glassEffect,
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

  Widget _buildLanguageCard(BuildContext context) {
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
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.language,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.languageDescription,
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
                value: _selectedLanguage,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.translate,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(AppLocalizations.of(context)!.systemLanguage),
                  ),
                  DropdownMenuItem(
                    value: 'es',
                    child: Text(AppLocalizations.of(context)!.spanish),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(AppLocalizations.of(context)!.english),
                  ),
                ],
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });

                    // Aplicar el cambio de idioma
                    await _saveLanguageSetting(newValue);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
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
            if (_isLoggedIn && LoginService().currentUser != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    LoginService().currentUser!.photoUrl ?? '',
                  ),
                ),
                title: Text(
                  LoginService().currentUser!.displayName ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  LoginService().currentUser!.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: Text(AppLocalizations.of(context).logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).loginRequired,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).loginToAccess,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _handleLogin,
                      icon: const Icon(Icons.login),
                      label: Text(AppLocalizations.of(context).login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
