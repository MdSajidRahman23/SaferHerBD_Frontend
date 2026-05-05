import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

// ─────────────────────────────────────────────────────────────────
//  SOS SERVICE  — "Store offline & retry" mechanism (NFR-1)
//
//  Web:     uses SharedPreferences (localStorage) as offline store
//  Android: uses SharedPreferences as well (sqflite removed for web compat)
// ─────────────────────────────────────────────────────────────────

class SosResult {
  final bool   success;
  final bool   wasOffline;
  final String message;
  final String messageBn;
  final double? latencyMs;

  SosResult({
    required this.success,
    required this.wasOffline,
    required this.message,
    required this.messageBn,
    this.latencyMs,
  });
}

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  final _auth = AuthService();
  final _uuid = const Uuid();
  StreamSubscription? _connectivitySub;

  // ── MAIN TRIGGER ──────────────────────────────────────────────
  Future<SosResult> trigger({String method = 'button'}) async {
    final triggeredAt = DateTime.now();
    final id = _uuid.v4();

    // Get GPS (skip on web if permission denied)
    double lat = 23.8103, lng = 90.4125;
    try {
      if (!kIsWeb) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    // Check connectivity
    final conn = await Connectivity().checkConnectivity();
    final isOnline = conn.firstOrNull != ConnectivityResult.none;

    if (isOnline) {
      return await _triggerOnline(
        id: id, lat: lat, lng: lng,
        method: method, triggeredAt: triggeredAt,
      );
    } else {
      return await _queueOffline(
        id: id, lat: lat, lng: lng,
        method: method, triggeredAt: triggeredAt,
      );
    }
  }

  // ── ONLINE PATH ───────────────────────────────────────────────
  Future<SosResult> _triggerOnline({
    required String id, required double lat, required double lng,
    required String method, required DateTime triggeredAt,
  }) async {
    final token = await _auth.getToken();
    if (token == null) {
      return SosResult(
        success: false, wasOffline: false,
        message: 'Not authenticated', messageBn: 'লগইন করুন',
      );
    }

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.sosTrigger),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': id, 'latitude': lat, 'longitude': lng,
          'trigger_method': method,
          'triggered_at': triggeredAt.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));

      final latencyMs = DateTime.now().difference(triggeredAt).inMilliseconds.toDouble();

      if (res.statusCode == 202) {
        final data = jsonDecode(res.body);
        return SosResult(
          success: true, wasOffline: false,
          message: 'Alert sent! ${data['notified_contacts_count']} contacts notified.',
          messageBn: 'সংকেত পাঠানো হয়েছে! ${data['notified_contacts_count']} জনকে জানানো হয়েছে।',
          latencyMs: latencyMs,
        );
      }
    } catch (_) {}

    return await _queueOffline(
      id: id, lat: lat, lng: lng, method: method, triggeredAt: triggeredAt,
    );
  }

  // ── OFFLINE PATH  (Store & Retry) ─────────────────────────────
  Future<SosResult> _queueOffline({
    required String id, required double lat, required double lng,
    required String method, required DateTime triggeredAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('offline_sos_queue') ?? [];
    existing.add(jsonEncode({
      'id': id, 'latitude': lat, 'longitude': lng,
      'trigger_method': method,
      'triggered_at': triggeredAt.toIso8601String(),
      'retry_count': 0,
    }));
    await prefs.setStringList('offline_sos_queue', existing);
    _watchConnectivity();

    return SosResult(
      success: true, wasOffline: true,
      message: 'SOS saved offline. Will send when connected.',
      messageBn: 'নেটওয়ার্ক নেই — সংরক্ষিত হয়েছে। সংযোগ পেলেই পাঠানো হবে।',
    );
  }

  // ── SYNC OFFLINE QUEUE ────────────────────────────────────────
  Future<void> syncOfflineQueue() async {
    final token = await _auth.getToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('offline_sos_queue') ?? [];
    if (raw.isEmpty) return;

    final payloads = raw.map((r) {
      final m = jsonDecode(r) as Map<String, dynamic>;
      return {
        'id': m['id'], 'latitude': m['latitude'],
        'longitude': m['longitude'],
        'trigger_method': m['trigger_method'],
        'triggered_at': m['triggered_at'],
      };
    }).toList();

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.sosSyncOffline),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'payloads': payloads}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        await prefs.remove('offline_sos_queue');
      }
    } catch (_) {
      // Exponential backoff handled server-side on next sync attempt
    }
  }

  // ── CONNECTIVITY WATCHER ──────────────────────────────────────
  void _watchConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncOfflineQueue();
      }
    });
  }

  // ── PENDING COUNT ─────────────────────────────────────────────
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('offline_sos_queue') ?? []).length;
  }

  // ── SHAKE DETECTION (Android only, noop on web) ───────────────
  void enableShakeDetection({required Function() onShake}) {
    if (kIsWeb) return;
    // sensors_plus works on Android — web skips this
  }

  void disableShakeDetection() {}

  void dispose() { _connectivitySub?.cancel(); }
}
