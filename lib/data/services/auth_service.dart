import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const _pinKey = 'auth_pin';
  static const _useBiometricsKey = 'use_biometrics';
  static const _useAuthKey = 'use_auth';

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  Future<bool> isBiometricsAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        debugPrint('Device does not support biometrics');
        return false;
      }

      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        debugPrint('Cannot check biometrics');
        return false;
      }

      final availableBiometrics = await _auth.getAvailableBiometrics();
      debugPrint('Available biometrics: $availableBiometrics');
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({
    String? localizedReason,
    void Function(String)? onError,
  }) async {
    try {
      // First check if biometrics is available
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        onError?.call('Biometric authentication not available');
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason ?? 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.message}');
      onError?.call(e.message ?? 'Authentication error');
      return false;
    } catch (e) {
      debugPrint('Unexpected error in biometric authentication: $e');
      onError?.call('Unexpected authentication error');
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == pin;
  }

  Future<void> setUseBiometrics(bool use) async {
    await _storage.write(key: _useBiometricsKey, value: use.toString());
  }

  Future<bool> getUseBiometrics() async {
    final value = await _storage.read(key: _useBiometricsKey);
    return value == 'true';
  }

  Future<void> setUseAuth(bool use) async {
    await _storage.write(key: _useAuthKey, value: use.toString());
  }

  Future<bool> getUseAuth() async {
    final value = await _storage.read(key: _useAuthKey);
    return value == 'true';
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }
}
