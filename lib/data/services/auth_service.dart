import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class AuthService {
  static const _pinKey = 'auth_pin';
  static const _useBiometricsKey = 'use_biometrics';
  static const _useAuthKey = 'use_auth';

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  Future<bool> isBiometricsAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
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
