import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class SosResult {
  final bool success;
  final bool wasOffline;
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

  // ────────────────────────────────────────────────────────────────
  //  MAIN TRIGGER
  // ────────────────────────────────────────────────────────────────
  Future<SosResult> trigger({String method = 'button'}) async {
    final triggeredAt = DateTime.now();
    final id = _uuid.v4();

    // Get GPS — graceful fallback to default Dhaka coords
    double lat = 23.8103, lng = 90.4125;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 6));
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }
    } catch (_) {
      // Continue with default coords — better to send SOS with rough location than fail entirely
    }

    // Check connectivity
    bool isOnline = true;
    try {
      final conn = await Connectivity().checkConnectivity();
      isOnline = conn.isNotEmpty && conn.first != ConnectivityResult.none;
    } catch (_) {
      isOnline = true; // assume online if check fails
    }

    if (isOnline) {
      return await _triggerOnline(
        id: id, lat: lat, lng: lng, method: method, triggeredAt: triggeredAt,
      );
    } else {
      return await _queueOffline(
        id: id, lat: lat, lng: lng, method: method, triggeredAt: triggeredAt,
      );
    }
  }

  // ────────────────────────────────────────────────────────────────
  //  ONLINE TRIGGER
  // ────────────────────────────────────────────────────────────────
  Future<SosResult> _triggerOnline({
    required String id,
    required double lat,
    required double lng,
    required String method,
    required DateTime triggeredAt,
  }) async {
    final token = await _auth.getToken();
    if (token == null) {
      return SosResult(
        success: false,
        wasOffline: false,
        message: 'Please log in first',
        messageBn: 'প্রথমে লগইন করুন',
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
          'id': id,
          'latitude': lat,
          'longitude': lng,
          'trigger_method': method,
          'triggered_at': triggeredAt.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 8));

      final latencyMs =
          DateTime.now().difference(triggeredAt).inMilliseconds.toDouble();

      if (res.statusCode == 202 || res.statusCode == 200) {
        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {}
        final notified = data['notified_contacts_count'] ?? 0;
        return SosResult(
          success: true,
          wasOffline: false,
          message: 'Alert sent! $notified contacts notified.',
          messageBn: notified > 0
              ? 'সংকেত পাঠানো হয়েছে! $notified জনকে জানানো হয়েছে।'
              : 'সংকেত পাঠানো হয়েছে! কোনো emergency contact যোগ করুন বেশি কার্যকর হবার জন্য।',
          latencyMs: latencyMs,
        );
      }

      // 401 — token expired
      if (res.statusCode == 401) {
        return SosResult(
          success: false,
          wasOffline: false,
          message: 'Session expired. Please log in again.',
          messageBn: 'সেশন শেষ — আবার লগইন করুন',
        );
      }

      // Any other error → queue offline
      return await _queueOffline(
        id: id, lat: lat, lng: lng, method: method, triggeredAt: triggeredAt,
      );
    } catch (_) {
      return await _queueOffline(
        id: id, lat: lat, lng: lng, method: method, triggeredAt: triggeredAt,
      );
    }
  }

  // ────────────────────────────────────────────────────────────────
  //  OFFLINE QUEUE (Store & Retry)
  // ────────────────────────────────────────────────────────────────
  Future<SosResult> _queueOffline({
    required String id,
    required double lat,
    required double lng,
    required String method,
    required DateTime triggeredAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('offline_sos_queue') ?? [];
    existing.add(jsonEncode({
      'id': id,
      'latitude': lat,
      'longitude': lng,
      'trigger_method': method,
      'triggered_at': triggeredAt.toIso8601String(),
    }));
    await prefs.setStringList('offline_sos_queue', existing);
    _watchConnectivity();

    return SosResult(
      success: true,
      wasOffline: true,
      message: 'Saved offline. Will send when connected.',
      messageBn: 'নেটওয়ার্ক নেই — সংরক্ষিত হয়েছে। সংযোগ পেলেই পাঠানো হবে।',
    );
  }

  // ────────────────────────────────────────────────────────────────
  //  SYNC OFFLINE QUEUE
  // ────────────────────────────────────────────────────────────────
  Future<void> syncOfflineQueue() async {
    final token = await _auth.getToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('offline_sos_queue') ?? [];
    if (raw.isEmpty) return;

    final payloads = raw.map((r) {
      try {
        return jsonDecode(r) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }).where((m) => m != null).toList();

    if (payloads.isEmpty) {
      await prefs.remove('offline_sos_queue');
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.sosSyncOffline),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'payloads': payloads}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        await prefs.remove('offline_sos_queue');
      }
    } catch (_) {
      // Will retry next time connectivity changes
    }
  }

  // ────────────────────────────────────────────────────────────────
  //  CONNECTIVITY WATCHER
  // ────────────────────────────────────────────────────────────────
  void _watchConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncOfflineQueue();
      }
    });
  }

  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('offline_sos_queue') ?? []).length;
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
