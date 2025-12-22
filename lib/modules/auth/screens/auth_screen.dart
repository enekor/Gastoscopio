import 'dart:io';

import 'package:cashly/data/services/shared_preferences_service.dart';
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
  String? _backgroundImagePath;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _checkBiometrics();
  }

  Future<void> _loadBackgroundImage() async {
    final path = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.backgroundImage,
    );
    if (mounted) {
      setState(() {
        _backgroundImagePath = path;
      });
    }
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
    final hasBackground = _backgroundImagePath != null && _backgroundImagePath!.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: hasBackground ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          if (hasBackground)
            Positioned.fill(
              child: Image.file(
                File(_backgroundImagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          if (hasBackground)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: hasBackground ? Colors.white : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).enterPinToAccess,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: hasBackground ? Colors.white : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: hasBackground ? 0 : 1,
                    color: hasBackground 
                        ? Colors.white.withOpacity(0.15) 
                        : Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: hasBackground ? BorderSide(color: Colors.white.withOpacity(0.3)) : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _pinController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).pin,
                          labelStyle: TextStyle(color: hasBackground ? Colors.white70 : null),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.pin, color: hasBackground ? Colors.white70 : null),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPin ? Icons.visibility_off : Icons.visibility,
                              color: hasBackground ? Colors.white70 : null,
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
                        style: TextStyle(
                          letterSpacing: 8, 
                          fontSize: 24,
                          color: hasBackground ? Colors.white : null,
                        ),
                        onSubmitted: (_) => _verifyPin(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _verifyPin,
                    style: hasBackground ? FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.25),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ) : null,
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
                          icon: Icon(
                            Icons.fingerprint,
                            color: hasBackground ? Colors.white : null,
                          ),
                          label: Text(
                            AppLocalizations.of(context).useBiometrics,
                            style: TextStyle(
                              color: hasBackground ? Colors.white : null,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
