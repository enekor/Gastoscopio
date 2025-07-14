import 'package:cashly/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

class SecuritySettingsCard extends StatefulWidget {
  const SecuritySettingsCard({super.key});

  @override
  State<SecuritySettingsCard> createState() => _SecuritySettingsCardState();
}

class _SecuritySettingsCardState extends State<SecuritySettingsCard> {
  final _authService = AuthService();
  final _pinController = TextEditingController();
  bool _useAuth = false;
  bool _useBiometrics = false;
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final useAuth = await _authService.getUseAuth();
    final useBiometrics = await _authService.getUseBiometrics();
    if (mounted) {
      setState(() {
        _useAuth = useAuth;
        _useBiometrics = useBiometrics;
      });
    }
  }

  Future<void> _showPinDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).setupPin),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).enterPinSetup),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).pin,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.pin),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPin ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPin = !_showPin;
                        });
                      },
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: !_showPin,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 8, fontSize: 24),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pinController.clear();
                },
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () async {
                  if (_pinController.text.length == 4) {
                    await _authService.setPin(_pinController.text);
                    await _authService.setUseAuth(true);
                    if (mounted) {
                      Navigator.of(context).pop();
                      setState(() {
                        _useAuth = true;
                      });
                      _pinController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context).pinSetupSuccess,
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: Text(AppLocalizations.of(context).save),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).security,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).securityDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(AppLocalizations.of(context).useAppLock),
              subtitle: Text(
                AppLocalizations.of(context).useAppLockDescription,
              ),
              value: _useAuth,
              onChanged: (bool value) async {
                if (value) {
                  await _showPinDialog();
                } else {
                  await _authService.setUseAuth(false);
                  await _authService.setUseBiometrics(false);
                  if (mounted) {
                    setState(() {
                      _useAuth = false;
                      _useBiometrics = false;
                    });
                  }
                }
              },
            ),
            if (_useAuth) ...[
              FutureBuilder<bool>(
                future: _authService.isBiometricsAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!) {
                    return SwitchListTile(
                      title: Text(AppLocalizations.of(context).useBiometrics),
                      subtitle: Text(
                        AppLocalizations.of(context).useBiometricsDescription,
                      ),
                      value: _useBiometrics,
                      onChanged: (bool value) async {
                        await _authService.setUseBiometrics(value);
                        if (mounted) {
                          setState(() {
                            _useBiometrics = value;
                          });
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context).changePin),
                subtitle: Text(
                  AppLocalizations.of(context).changePinDescription,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPinDialog,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
