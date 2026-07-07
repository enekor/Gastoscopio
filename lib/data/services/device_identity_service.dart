import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentityService {
  static const String _keyDeviceUuid = 'device_uuid';
  static const String _keyFriendlyName = 'device_friendly_name';
  static const String _keyTrustedPeerUuid = 'trusted_peer_uuid';
  static const String _keyTrustedPeerName = 'trusted_peer_name';

  static final DeviceIdentityService _instance = DeviceIdentityService._internal();

  factory DeviceIdentityService() {
    return _instance;
  }

  DeviceIdentityService._internal();

  Future<String> getOrCreateDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_keyDeviceUuid);
    if (uuid == null) {
      uuid = const Uuid().v4();
      await prefs.setString(_keyDeviceUuid, uuid);
    }
    return uuid;
  }

  Future<String> getFriendlyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFriendlyName) ?? 'Mi Dispositivo';
  }

  Future<void> setFriendlyName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFriendlyName, name);
  }

  Future<Map<String, String>?> getTrustedPeer() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString(_keyTrustedPeerUuid);
    final name = prefs.getString(_keyTrustedPeerName);
    if (uuid != null && name != null) {
      return {'uuid': uuid, 'name': name};
    }
    return null;
  }

  Future<void> setTrustedPeer(String uuid, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTrustedPeerUuid, uuid);
    await prefs.setString(_keyTrustedPeerName, name);
  }

  Future<void> clearTrustedPeer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTrustedPeerUuid);
    await prefs.remove(_keyTrustedPeerName);
  }

  String buildAdvertiseName(String uuid, String friendlyName) {
    return '$uuid::$friendlyName';
  }

  Map<String, String>? parseAdvertiseName(String name) {
    final parts = name.split('::');
    if (parts.length == 2) {
      return {'uuid': parts[0], 'name': parts[1]};
    }
    return null;
  }
}
