import 'dart:io';

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
import 'package:file_picker/file_picker.dart';
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
  String? _backgroundImagePath;

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
                onPressed: () => Navigator.pop(context),
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

      for (Month month in result['Months']) {
        await SqliteService().db.monthDao.insertMonth(month);
      }
      for (MovementValue movement in result['Movements']) {
        movement.category = movement.category?.trim();
        await SqliteService().db.movementValueDao.insertMovementValue(movement);
      }
      if (result.containsKey('FixedMovements')) {
        for (FixedMovement fixedMovement in result['FixedMovements']) {
          await SqliteService().db.fixedMovementDao.insertFixedMovement(fixedMovement);
        }
      }

      await LoginService().uploadDatabase();
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.dataImportedSuccessfully),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      try { Navigator.pop(context); } catch (_) {}

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.importError),
            content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.accept),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _loadData() async {
    final prefs = SharedPreferencesService();
    final currency = await prefs.getStringValue(SharedPreferencesKeys.currency);
    final isSvg = await prefs.getBoolValue(SharedPreferencesKeys.isSvgAvatar);
    final avatarColor = await prefs.getStringValue(SharedPreferencesKeys.avatarColor);
    final isOpaque = await prefs.getBoolValue(SharedPreferencesKeys.isOpaqueBottomNav);
    final language = await prefs.getStringValue(SharedPreferencesKeys.selectedLanguage);
    final bg = await prefs.getStringValue(SharedPreferencesKeys.backgroundImage);

    if (mounted) {
      setState(() {
        if (currency != null) _currentCurrency = currency;
        if (isSvg != null) _isSvg = isSvg;
        if (avatarColor != null) {
          _r = int.tryParse(avatarColor.split(",")[0]) ?? 255;
          _g = int.tryParse(avatarColor.split(",")[1]) ?? 255;
          _b = int.tryParse(avatarColor.split(",")[2]) ?? 255;
        }
        if (isOpaque != null) _isOpaqueBottomNav = isOpaque;
        _selectedLanguage = language ?? 'system';
        _backgroundImagePath = bg;
      });
    }
  }

  Future<void> _saveCurrency(String currency) async {
    await SharedPreferencesService().setStringValue(SharedPreferencesKeys.currency, currency);
    setState(() => _currentCurrency = currency);
  }

  Future<void> _saveLogo() async {
    await SharedPreferencesService().setBoolValue(SharedPreferencesKeys.isSvgAvatar, _isSvg);
  }

  Future<void> _saveAvatarColor(int r, int g, int b) async {
    await SharedPreferencesService().setStringValue(SharedPreferencesKeys.avatarColor, '$r,$g,$b');
  }

  Future<void> _saveBottomNavStyle(bool isOpaque) async {
    await SharedPreferencesService().setBoolValue(SharedPreferencesKeys.isOpaqueBottomNav, isOpaque);
    setState(() => _isOpaqueBottomNav = isOpaque);
  }

  Future<void> _saveLanguageSetting(String languageCode) async {
    await LocaleService().setLocale(languageCode == 'system' ? null : languageCode);
  }

  Future<void> _selectBackgroundImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      await SharedPreferencesService().setStringValue(SharedPreferencesKeys.backgroundImage, path);
      setState(() => _backgroundImagePath = path);
    }
  }

  Future<void> _removeBackgroundImage() async {
    await SharedPreferencesService().setStringValue(SharedPreferencesKeys.backgroundImage, "");
    setState(() => _backgroundImagePath = null);
  }

  Future<void> _handleLogout() async {
    await LoginService().signOut();
    setState(() => _isLoggedIn = false);
  }

  Future<void> _handleLogin() async {
    final success = await LoginService().signIn();
    if (success.isSuccess) setState(() => _isLoggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            pinned: true,
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.of(context)!.settings,
              style: const TextStyle(
                fontFamily: 'Pacifico',
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, AppLocalizations.of(context).accountSection, AppLocalizations.of(context).accountDescription, Icons.account_circle_outlined),
                  const SizedBox(height: 20),
                  _buildAccountCard(context),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildSectionHeader(context, AppLocalizations.of(context)!.personalization, AppLocalizations.of(context)!.personalizationSubtitle, Icons.palette_outlined),
                  const SizedBox(height: 20),
                  _buildLanguageCard(context),
                  const SizedBox(height: 20),
                  _buildCurrencyCard(context),
                  const SizedBox(height: 20),
                  _buildLogoCard(context),
                  const SizedBox(height: 20),
                  _buildBackgroundImageCard(context),
                  const SizedBox(height: 20),
                  _buildBottomNavCard(context),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildSectionHeader(context, AppLocalizations.of(context).security, AppLocalizations.of(context).securityDescription, Icons.security),
                  const SizedBox(height: 20),
                  const SecuritySettingsCard(),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildSectionHeader(context, AppLocalizations.of(context)!.backupManagement, AppLocalizations.of(context)!.backupDescription, Icons.backup_outlined),
                  const SizedBox(height: 20),
                  const BackupRestoreWidget(),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  DeveloperOptionsWidget(onImportSuccess: _handleImportSuccess),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.currency_exchange, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.currency, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.currencyDescription, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currentCurrency,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary)),
              items: ['€', '\$', '£', '¥', 'CHF', 'COP'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) { if (v != null) _saveCurrency(v); },
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.logoPersonalization, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildLogoOption(context, isPng: true, isSelected: !_isSvg, onTap: () { setState(() => _isSvg = false); _saveLogo(); })),
                const SizedBox(width: 16),
                Expanded(child: _buildLogoOption(context, isPng: false, isSelected: _isSvg, onTap: () { setState(() => _isSvg = true); _saveLogo(); })),
              ],
            ),
            if (_isSvg) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.color_lens_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.svgColorLabel, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: CircleAvatar(radius: 16, backgroundColor: Color.fromARGB(255, _r, _g, _b), child: Icon(Icons.edit, size: 16, color: _getContrastColor(Color.fromARGB(255, _r, _g, _b)))),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoOption(BuildContext context, {required bool isPng, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withAlpha(100), width: isSelected ? 2 : 1), color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(25) : Theme.of(context).colorScheme.surface),
        child: Column(
          children: [
            SizedBox(height: 40, child: isPng ? Image.asset('assets/logo.png') : SvgPicture.asset('assets/logo.svg', colorFilter: ColorFilter.mode(Color.fromARGB(255, _r, _g, _b), BlendMode.srcIn))),
            const SizedBox(height: 8),
            Text(isPng ? 'PNG' : 'SVG', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).colorScheme.primary : null)),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectColor),
        content: SingleChildScrollView(child: ColorPicker(pickerColor: Color.fromARGB(255, _r, _g, _b), onColorChanged: (c) => setState(() { _r = c.red; _g = c.green; _b = c.blue; }), enableAlpha: false)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(onPressed: () { _saveAvatarColor(_r, _g, _b); Navigator.pop(context); }, child: Text(AppLocalizations.of(context)!.apply)),
        ],
      ),
    );
  }

  Color _getContrastColor(Color color) => (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255 > 0.5 ? Colors.black : Colors.white;

  Widget _buildBackgroundImageCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.wallpaper_outlined, color: Theme.of(context).colorScheme.primary, size: 20), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.backgroundImage, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 16),
            if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty) ...[ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_backgroundImagePath!), height: 100, width: double.infinity, fit: BoxFit.cover)), const SizedBox(height: 12)],
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: _selectBackgroundImage, icon: const Icon(Icons.photo_library), label: Text(AppLocalizations.of(context)!.selectImage))),
                if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty) ...[const SizedBox(width: 8), IconButton(onPressed: _removeBackgroundImage, icon: const Icon(Icons.delete), color: Theme.of(context).colorScheme.error)],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.navigation_outlined, color: Theme.of(context).colorScheme.primary, size: 20), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.navigationStyle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildNavOption(context, isOpaque: false, isSelected: !_isOpaqueBottomNav, onTap: () => _saveBottomNavStyle(false))),
                const SizedBox(width: 16),
                Expanded(child: _buildNavOption(context, isOpaque: true, isSelected: _isOpaqueBottomNav, onTap: () => _saveBottomNavStyle(true))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavOption(BuildContext context, {required bool isOpaque, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withAlpha(100), width: isSelected ? 2 : 1)),
        child: Text(isOpaque ? 'Opaca' : 'Transparente', textAlign: TextAlign.center, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).colorScheme.primary : null)),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.language, color: Theme.of(context).colorScheme.primary, size: 20), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.language, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))]),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.translate)),
              items: [
                DropdownMenuItem(value: 'system', child: Text(AppLocalizations.of(context)!.systemLanguage)),
                DropdownMenuItem(value: 'es', child: Text(AppLocalizations.of(context)!.spanish)),
                DropdownMenuItem(value: 'en', child: Text(AppLocalizations.of(context)!.english)),
              ],
              onChanged: (v) { if (v != null) { setState(() => _selectedLanguage = v); _saveLanguageSetting(v); } },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final user = LoginService().currentUser;
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoggedIn && user != null
            ? Column(
                children: [
                  ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundImage: NetworkImage(user.photoUrl ?? '')), title: Text(user.displayName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(user.email)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: _handleLogout, icon: const Icon(Icons.logout), label: Text(AppLocalizations.of(context).logout), style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.errorContainer, foregroundColor: Theme.of(context).colorScheme.onErrorContainer)),
                ],
              )
            : Center(child: ElevatedButton.icon(onPressed: _handleLogin, icon: const Icon(Icons.login), label: Text(AppLocalizations.of(context).login))),
      ),
    );
  }
}
