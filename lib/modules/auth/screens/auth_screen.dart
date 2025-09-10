import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:cashly/data/services/auth_service.dart';
import 'package:cashly/l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _showPin = false;
  bool _checkingBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    if (_checkingBiometrics) return; // Prevent multiple simultaneous checks
    _checkingBiometrics = true;

    try {
      final useBiometrics = await _authService.getUseBiometrics();
      if (useBiometrics && await _authService.isBiometricsAvailable()) {
        final success = await _authService.authenticateWithBiometrics(
          localizedReason: AppLocalizations.of(context).authenticateToAccess,
          onError: (p0) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(p0),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          ),
        );

        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else if (mounted) {
          // Only show error if authentication failed (not if user cancelled)
          if (success == false) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).biometricAuthFailed),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } finally {
      _checkingBiometrics = false;
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isValid = await _authService.verifyPin(_pinController.text);
      if (mounted) {
        if (isValid) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).invalidPin),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _pinController.clear(); // Clear the PIN on error
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).enterPinToAccess,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                onSubmitted: (_) => _verifyPin(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _verifyPin,
                child: _isLoading
                    ? SizedBox(height: 20, width: 20, child: Loading(context))
                    : Text(AppLocalizations.of(context).verify),
              ),
              const SizedBox(height: 16),
              FutureBuilder<bool>(
                future: _authService.isBiometricsAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!) {
                    return TextButton.icon(
                      onPressed: _checkingBiometrics ? null : _checkBiometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(AppLocalizations.of(context).useBiometrics),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
