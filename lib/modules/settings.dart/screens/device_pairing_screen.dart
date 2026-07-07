import 'package:cashly/data/services/device_identity_service.dart';
import 'package:cashly/data/services/nearby_service.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  final DeviceIdentityService _identityService = DeviceIdentityService();
  final NearbyService _nearbyService = NearbyService();
  
  bool _isScanning = false;
  Map<String, String>? _trustedPeer;
  String _statusMessage = '';
  List<Map<String, dynamic>> _foundDevices = [];

  @override
  void initState() {
    super.initState();
    _loadTrustedPeer();
    _startScanning();
  }

  @override
  void dispose() {
    _stopScanning();
    super.dispose();
  }

  Future<void> _loadTrustedPeer() async {
    final peer = await _identityService.getTrustedPeer();
    if (mounted) {
      setState(() {
        _trustedPeer = peer;
      });
    }
  }

  Future<void> _startScanning() async {
    if (!await _nearbyService.ensurePermissions()) {
      setState(() {
        _statusMessage = 'Permisos denegados';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Buscando dispositivos...';
      _foundDevices.clear();
    });

    final myUuid = await _identityService.getOrCreateDeviceUuid();
    final myName = await _identityService.getFriendlyName();
    final advertiseName = _identityService.buildAdvertiseName(myUuid, myName);

    try {
      // Start advertising
      await Nearby().startAdvertising(
        advertiseName,
        _nearbyService.strategy,
        onConnectionInitiated: (id, info) async {
          final parsed = _identityService.parseAdvertiseName(info.endpointName);
          if (parsed != null) {
            // Accept connection automatically for pairing
            await Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (endpointId, payload) {},
              onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
            );
            
            // Store temporarily to save on success
            _foundDevices.add({
              'id': id,
              'uuid': parsed['uuid'],
              'name': parsed['name'],
            });
          } else {
            await Nearby().rejectConnection(id);
          }
        },
        onConnectionResult: (id, status) async {
          if (status == Status.CONNECTED) {
            final device = _foundDevices.firstWhere((d) => d['id'] == id, orElse: () => {});
            if (device.isNotEmpty) {
              await _identityService.setTrustedPeer(device['uuid'], device['name']);
              await _loadTrustedPeer();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispositivo vinculado correctamente')),
                );
              }
            }
            await Future.delayed(const Duration(seconds: 1));
            await _stopScanning();
          }
        },
        onDisconnected: (id) {},
        serviceId: _nearbyService.serviceId,
      );

      // Start discovery
      await Nearby().startDiscovery(
        myName,
        _nearbyService.strategy,
        onEndpointFound: (id, name, serviceId) async {
          final parsed = _identityService.parseAdvertiseName(name);
          if (parsed != null) {
            setState(() {
              // Add if not exists
              if (!_foundDevices.any((d) => d['id'] == id)) {
                _foundDevices.add({
                  'id': id,
                  'uuid': parsed['uuid'],
                  'name': parsed['name'],
                  'endpointName': name,
                });
              }
            });
          }
        },
        onEndpointLost: (id) {
          setState(() {
            _foundDevices.removeWhere((d) => d['id'] == id);
          });
        },
        serviceId: _nearbyService.serviceId,
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error al escanear: $e';
      });
    }
  }

  Future<void> _stopScanning() async {
    await _nearbyService.stopAll();
    if (mounted) {
      setState(() {
        _isScanning = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _pairWithDevice(Map<String, dynamic> device) async {
    setState(() {
      _statusMessage = 'Vinculando con ${device['name']}...';
    });

    final myUuid = await _identityService.getOrCreateDeviceUuid();
    final myName = await _identityService.getFriendlyName();
    final advertiseName = _identityService.buildAdvertiseName(myUuid, myName);

    try {
      await Nearby().requestConnection(
        advertiseName,
        device['id'],
        onConnectionInitiated: (id, info) async {
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {},
            onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
          );
        },
        onConnectionResult: (id, status) async {
          if (status == Status.CONNECTED) {
            await _identityService.setTrustedPeer(device['uuid'], device['name']);
            await _loadTrustedPeer();
            await _stopScanning();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dispositivo vinculado correctamente')),
              );
            }
          } else {
            setState(() {
              _statusMessage = 'Error al vincular';
            });
          }
        },
        onDisconnected: (id) {},
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al solicitar conexión: $e';
      });
    }
  }

  Future<void> _unpair() async {
    await _identityService.clearTrustedPeer();
    await _loadTrustedPeer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular dispositivo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_trustedPeer != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 8),
                      const Text('Dispositivo vinculado:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_trustedPeer!['name']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _unpair,
                        icon: const Icon(Icons.link_off),
                        label: const Text('Desvincular'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            if (_isScanning) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Center(child: Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _stopScanning,
                child: const Text('Detener búsqueda'),
              ),
              const SizedBox(height: 16),
              const Text('Dispositivos encontrados:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: _foundDevices.length,
                  itemBuilder: (context, index) {
                    final device = _foundDevices[index];
                    return ListTile(
                      leading: const Icon(Icons.smartphone),
                      title: Text(device['name']),
                      trailing: ElevatedButton(
                        onPressed: () => _pairWithDevice(device),
                        child: const Text('Vincular'),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text(
                'Para sincronizar los movimientos de la tarjeta de crédito, necesitas vincular otro dispositivo. Ambos dispositivos deben estar en esta pantalla.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.search),
                label: const Text('Buscar dispositivos'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
