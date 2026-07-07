import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cashly/data/models/credit_card_expense.dart';
import 'package:cashly/data/services/device_identity_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

enum SyncResult { ok, peerNotFound, error }

class NearbyService {
  static final NearbyService _instance = NearbyService._internal();
  final String serviceId = "com.N3k0chan.cashly.ccsync";
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;

  factory NearbyService() {
    return _instance;
  }

  NearbyService._internal();

  Future<bool> ensurePermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.location.isDenied) {
        await Permission.location.request();
      }
      if (await Permission.bluetooth.isDenied) {
        await Permission.bluetooth.request();
      }
      if (await Permission.bluetoothConnect.isDenied) {
        await Permission.bluetoothConnect.request();
      }
      if (await Permission.bluetoothAdvertise.isDenied) {
        await Permission.bluetoothAdvertise.request();
      }
      if (await Permission.bluetoothScan.isDenied) {
        await Permission.bluetoothScan.request();
      }
      if (await Permission.nearbyWifiDevices.isDenied) {
        await Permission.nearbyWifiDevices.request();
      }

      bool locationGranted = await Permission.location.isGranted;
      bool bluetoothGranted = await Permission.bluetooth.isGranted || await Permission.bluetoothConnect.isGranted;
      
      return locationGranted && bluetoothGranted;
    }
    return false;
  }

  Future<SyncResult> sendMovements({
    required List<CreditCardExpense> movements,
    required String trustedPeerUuid,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!await ensurePermissions()) return SyncResult.error;

    final identity = DeviceIdentityService();
    final myUuid = await identity.getOrCreateDeviceUuid();
    final myName = await identity.getFriendlyName();
    final advertiseName = identity.buildAdvertiseName(myUuid, myName);

    Completer<SyncResult> completer = Completer();
    String? connectedEndpointId;

    try {
      await Nearby().startAdvertising(
        advertiseName,
        strategy,
        onConnectionInitiated: (id, info) async {
          final parsed = identity.parseAdvertiseName(info.endpointName);
          if (parsed != null && parsed['uuid'] == trustedPeerUuid) {
            await Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (endpointId, payload) {},
              onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {
                if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
                  if (!completer.isCompleted) completer.complete(SyncResult.ok);
                } else if (payloadTransferUpdate.status == PayloadStatus.FAILURE) {
                  if (!completer.isCompleted) completer.complete(SyncResult.error);
                }
              },
            );
          } else {
            await Nearby().rejectConnection(id);
          }
        },
        onConnectionResult: (id, status) async {
          if (status == Status.CONNECTED) {
            connectedEndpointId = id;
            
            // Send payload
            final payloadJson = {
              "type": "cc_movements_sync",
              "version": 1,
              "sentAt": DateTime.now().millisecondsSinceEpoch,
              "movements": movements.map((m) => {
                "id": m.uuid,
                "amount": m.amount,
                "date": m.date,
                "description": m.description,
                "day": m.day,
                "ts": m.ts,
              }).toList()
            };
            
            final bytes = utf8.encode(jsonEncode(payloadJson));
            await Nearby().sendBytesPayload(id, bytes);
          } else if (status == Status.REJECTED || status == Status.ERROR) {
            if (!completer.isCompleted) completer.complete(SyncResult.error);
          }
        },
        onDisconnected: (id) {
          if (!completer.isCompleted) completer.complete(SyncResult.error);
        },
        serviceId: serviceId,
      );

      await Nearby().startDiscovery(
        myName,
        strategy,
        onEndpointFound: (id, name, serviceId) async {
          final parsed = identity.parseAdvertiseName(name);
          if (parsed != null && parsed['uuid'] == trustedPeerUuid) {
            await Nearby().requestConnection(
              advertiseName,
              id,
              onConnectionInitiated: (id, info) async {
                await Nearby().acceptConnection(
                  id,
                  onPayLoadRecieved: (endpointId, payload) {},
                  onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {
                    if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
                      if (!completer.isCompleted) completer.complete(SyncResult.ok);
                    } else if (payloadTransferUpdate.status == PayloadStatus.FAILURE) {
                      if (!completer.isCompleted) completer.complete(SyncResult.error);
                    }
                  },
                );
              },
              onConnectionResult: (id, status) async {
                if (status == Status.CONNECTED) {
                  connectedEndpointId = id;
                  
                  // Send payload
                  final payloadJson = {
                    "type": "cc_movements_sync",
                    "version": 1,
                    "sentAt": DateTime.now().millisecondsSinceEpoch,
                    "movements": movements.map((m) => {
                      "id": m.uuid,
                      "amount": m.amount,
                      "date": m.date,
                      "description": m.description,
                      "day": m.day,
                      "ts": m.ts,
                    }).toList()
                  };
                  
                  final bytes = utf8.encode(jsonEncode(payloadJson));
                  await Nearby().sendBytesPayload(id, bytes);
                } else if (status == Status.REJECTED || status == Status.ERROR) {
                  if (!completer.isCompleted) completer.complete(SyncResult.error);
                }
              },
              onDisconnected: (id) {
                if (!completer.isCompleted) completer.complete(SyncResult.error);
              },
            );
          }
        },
        onEndpointLost: (id) {},
        serviceId: serviceId,
      );

      // Timeout logic
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(SyncResult.peerNotFound);
        }
      });

      return await completer.future;
    } catch (e) {
      return SyncResult.error;
    } finally {
      await stopAll();
    }
  }

  Future<void> startReceivingMode(int currentMonthId, Function onDataReceived) async {
    if (!await ensurePermissions()) return;

    final identity = DeviceIdentityService();
    final myUuid = await identity.getOrCreateDeviceUuid();
    final myName = await identity.getFriendlyName();
    final advertiseName = identity.buildAdvertiseName(myUuid, myName);
    
    final trustedPeer = await identity.getTrustedPeer();
    if (trustedPeer == null) return;
    
    final trustedPeerUuid = trustedPeer['uuid'];

    try {
      await Nearby().startAdvertising(
        advertiseName,
        strategy,
        onConnectionInitiated: (id, info) async {
          final parsed = identity.parseAdvertiseName(info.endpointName);
          if (parsed != null && parsed['uuid'] == trustedPeerUuid) {
            await Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (endpointId, payload) async {
                if (payload.type == PayloadType.BYTES) {
                  try {
                    final jsonStr = utf8.decode(payload.bytes!);
                    final data = jsonDecode(jsonStr);
                    
                    if (data['type'] == 'cc_movements_sync') {
                      await _mergeMovements(data['movements'], currentMonthId);
                      onDataReceived();
                    }
                  } catch (e) {
                    print("Error parsing payload: $e");
                  }
                }
              },
              onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
            );
          } else {
            await Nearby().rejectConnection(id);
          }
        },
        onConnectionResult: (id, status) {},
        onDisconnected: (id) {},
        serviceId: serviceId,
      );
    } catch (e) {
      print("Error starting receiving mode: $e");
    }
  }

  Future<void> _mergeMovements(List<dynamic> incomingMovements, int currentMonthId) async {
    final db = SqliteService().db;
    final currentExpenses = await db.creditCardExpenseDao.findExpensesByMonthId(currentMonthId);
    
    for (var incoming in incomingMovements) {
      final incomingId = incoming['id'];
      final incomingTs = incoming['ts'];
      
      final existing = currentExpenses.where((e) => e.uuid == incomingId).firstOrNull;
      
      if (existing == null) {
        // Insert
        final newExpense = CreditCardExpense(
          monthId: currentMonthId,
          description: incoming['description'],
          amount: incoming['amount'].toDouble(),
          day: incoming['day'],
          date: incoming['date'],
          uuid: incomingId,
          ts: incomingTs,
        );
        await db.creditCardExpenseDao.insertExpense(newExpense);
      } else {
        // Update if incoming is newer
        if (incomingTs > existing.ts) {
          final updatedExpense = CreditCardExpense(
            id: existing.id,
            monthId: currentMonthId,
            description: incoming['description'],
            amount: incoming['amount'].toDouble(),
            day: incoming['day'],
            date: incoming['date'],
            uuid: incomingId,
            ts: incomingTs,
          );
          await db.creditCardExpenseDao.updateExpense(updatedExpense);
        }
      }
    }
  }

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
  }
}
