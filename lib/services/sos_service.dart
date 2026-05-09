import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart' as bp;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../utils/constants.dart';
import 'auth_service.dart';

/// SosService — orchestrates SOS triggering with offline-first guarantee.
class SosService {
  static const _kQueue = 'sh_sos_offline_queue';
  static const _uuid = Uuid();

  final _auth = AuthService();
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  /// Initialize background sync
  Future<void> startConnectivityWatcher() async {
    final c = Connectivity();
    _connSub?.cancel();
    _connSub = c.onConnectivityChanged.listen((results) async {
      if (results.any((r) => r != ConnectivityResult.none)) {
        await syncOfflineQueue();
      }
    });
  }

  Future<void> stopConnectivityWatcher() async {
    await _connSub?.cancel();
    _connSub = null;
  }

  /// UPDATE: Added 'trigger' alias to match SosScreen's call
  /// This solves the "method 'trigger' isn't defined" error
  Future<Map<String, dynamic>> trigger({String triggerMethod = 'button', double? lat, double? lng}) async {
    return await triggerSos(triggerMethod: triggerMethod);
  }

  /// Public trigger entrypoint.
  Future<Map<String, dynamic>> triggerSos({String triggerMethod = 'button'}) async {
    final pos = await _bestEffortPosition();
    final battery = await _bestEffortBattery();
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    final payload = {
      'id': id,
      'latitude': pos?.latitude ?? 0.0,
      'longitude': pos?.longitude ?? 0.0,
      'trigger_method': triggerMethod,
      'triggered_at': now,
      if (battery != null) 'battery_level': battery,
    };

    // Try direct online dispatch first
    final online = await _tryOnlineTrigger(payload);
    if (online['success'] == true) {
      return online;
    }

    // Fallback: enqueue for later
    await _enqueue(payload);
    return {
      'success': true,
      'offline': true,
      'sos_id': id,
      'message': 'Queued — will send when online.',
    };
  }

  // ─── ONLINE TRIGGER ───────────────────────────────────────
  Future<Map<String, dynamic>> _tryOnlineTrigger(Map<String, dynamic> payload) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'reason': 'no_token'};
      }
      final res = await http.post(
        Uri.parse(ApiConfig.sosTrigger),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 202 || res.statusCode == 200) {
        try {
          return jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {
          return {'success': true, 'sos_id': payload['id']};
        }
      }
      return {'success': false, 'http': res.statusCode};
    } on TimeoutException {
      return {'success': false, 'reason': 'timeout'};
    } on SocketException {
      return {'success': false, 'reason': 'no_network'};
    } catch (_) {
      return {'success': false, 'reason': 'unknown'};
    }
  }

  // ─── OFFLINE QUEUE ────────────────────────────────────────
  Future<void> _enqueue(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kQueue) ?? [];
    list.add(jsonEncode(payload));
    await prefs.setStringList(_kQueue, list);
  }

  Future<int> getQueueSize() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kQueue) ?? []).length;
  }

  Future<int> syncOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kQueue) ?? [];
    if (list.isEmpty) return 0;

    final token = await _auth.getToken();
    if (token == null) return 0;

    final payloads = list.map((s) {
      try { return jsonDecode(s); } catch (_) { return null; }
    }).where((e) => e != null).toList();

    if (payloads.isEmpty) {
      await prefs.remove(_kQueue);
      return 0;
    }

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.sosSyncOffline),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'payloads': payloads}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        await prefs.remove(_kQueue);
        try {
          final body = jsonDecode(res.body);
          return (body['synced_count'] as int?) ?? payloads.length;
        } catch (_) {
          return payloads.length;
        }
      }
    } catch (_) {/* will retry on next connectivity event */}

    return 0;
  }

  // ─── HELPERS ──────────────────────────────────────────────
  Future<Position?> _bestEffortPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return null;

      // UPDATE: Fix for Geolocator 12.0.0+
      // Using direct parameters instead of locationSettings to avoid mismatch
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, 
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  Future<int?> _bestEffortBattery() async {
    try {
      final battery = bp.Battery();
      return await battery.batteryLevel.timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }
}