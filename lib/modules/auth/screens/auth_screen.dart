import 'dart:io';
import 'dart:ui';

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
    if (_checkingBiometrics) return; 
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
          _pinController.clear(); 
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
      body: Stack(
        children: [
          // Fondo
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
          
          // Overlay oscuro mucho más intenso para mejorar contraste
          Positioned.fill(
            child: Container(
              color: hasBackground 
                  ? Colors.black.withOpacity(0.75) 
                  : Theme.of(context).colorScheme.surface,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono Lock estilizado
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: hasBackground ? Colors.white.withOpacity(0.1) : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: hasBackground ? Border.all(color: Colors.white.withOpacity(0.2)) : null,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 80,
                        color: hasBackground ? Colors.white : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      AppLocalizations.of(context).enterPinToAccess,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasBackground ? Colors.white : null,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    // Contenedor PIN con Glassmorphism premium
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            decoration: BoxDecoration(
                              color: hasBackground 
                                  ? Colors.white.withOpacity(0.1) 
                                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: hasBackground 
                                    ? Colors.white.withOpacity(0.2) 
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _pinController,
                                  obscureText: !_showPin,
                                  maxLength: 4,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  autofocus: true,
                                  cursorColor: hasBackground ? Colors.white : null,
                                  style: TextStyle(
                                    letterSpacing: 24, 
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: hasBackground ? Colors.white : null,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    border: InputBorder.none,
                                    hintText: "••••",
                                    hintStyle: TextStyle(
                                      color: hasBackground ? Colors.white24 : null,
                                      letterSpacing: 24,
                                    ),
                                  ),
                                  onSubmitted: (_) => _verifyPin(),
                                ),
                                if (hasBackground)
                                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Icon(
                                      _showPin ? Icons.visibility_off : Icons.visibility,
                                      color: hasBackground ? Colors.white60 : null,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPin = !_showPin;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Botón Verify Sólido
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 300),
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasBackground ? Colors.white : Theme.of(context).colorScheme.primary,
                          foregroundColor: hasBackground ? Colors.black : Theme.of(context).colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(height: 24, width: 24, child: Loading(context))
                            : Text(
                                AppLocalizations.of(context).verify.toUpperCase(),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Biometría
                    FutureBuilder<bool>(
                      future: _authService.isBiometricsAvailable(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!) {
                          return TextButton.icon(
                            onPressed: _checkingBiometrics ? null : _checkBiometrics,
                            icon: Icon(
                              Icons.fingerprint_rounded,
                              color: hasBackground ? Colors.white70 : null,
                              size: 28,
                            ),
                            label: Text(
                              AppLocalizations.of(context).useBiometrics,
                              style: TextStyle(
                                color: hasBackground ? Colors.white70 : null,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              backgroundColor: hasBackground ? Colors.white.withOpacity(0.05) : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
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
          ),
        ],
      ),
    );
  }
}
