import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../utils/constants.dart';
import 'auth_service.dart';

/// Result of an SOS dispatch operation.
///
/// **Two ways to read the result:**
///   1. Object access (recommended): `result.success`, `result.wasOffline`
///   2. Map access (legacy): `result['success']`, `result['offline']`
class SosResult {
  final bool success;
  final bool wasOffline;
  final String message;
  final String messageBn;
  final double? latencyMs;
  final int notifiedContactsCount;
  final int totalContacts;
  final String? sosId;
  final String dispatchStatus;
  final int fcmCount;
  final int smsCount;
  final double? serverAckLatencyMs;

  SosResult({
    required this.success,
    required this.wasOffline,
    required this.message,
    required this.messageBn,
    this.latencyMs,
    this.notifiedContactsCount = 0,
    this.totalContacts = 0,
    this.sosId,
    this.dispatchStatus = 'unknown',
    this.fcmCount = 0,
    this.smsCount = 0,
    this.serverAckLatencyMs,
  });

  Map<String, dynamic> toMap() => {
        'success': success,
        'offline': wasOffline,
        'queued_offline': wasOffline,
        'message': message,
        'message_bn': messageBn,
        'latency_ms': latencyMs,
        'notified_contacts_count': notifiedContactsCount,
        'total_contacts': totalContacts,
        'sos_id': sosId,
        'dispatch_status': dispatchStatus,
        'fcm_count': fcmCount,
        'sms_count': smsCount,
        'server_ack_latency_ms': serverAckLatencyMs,
      };

  dynamic operator [](String key) => toMap()[key];
  bool containsKey(String key) => toMap().containsKey(key);

  @override
  String toString() =>
      'SosResult(success: $success, offline: $wasOffline, msg: $message)';
}

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  static const _kQueueKey = 'offline_sos_queue';
  final _auth = AuthService();
  final _uuid = const Uuid();
  StreamSubscription? _connectivitySub;

  Future<SosResult> trigger({
    double? lat,
    double? lng,
    String? triggerMethod,
    String? method,
  }) async {
    final triggeredAt = DateTime.now();
    final id = _uuid.v4();
    final m = triggerMethod ?? method ?? 'button';

    double? resolvedLat = lat;
    double? resolvedLng = lng;

    if (resolvedLat == null || resolvedLng == null) {
      try {
        final pos = await _getPosition();
        if (pos != null) {
          resolvedLat = pos.latitude;
          resolvedLng = pos.longitude;
        }
      } catch (_) {}
    }

    if (resolvedLat == null || resolvedLng == null) {
      return SosResult(
        success: false,
        wasOffline: false,
        message: 'Location is required for SOS. Please enable GPS/location permission and try again.',
        messageBn: 'SOS পাঠাতে সঠিক লোকেশন দরকার। GPS/location permission চালু করে আবার চেষ্টা করুন।',
        sosId: id,
      );
    }

    // Always try the server first. On web/Chrome, connectivity_plus can
    // incorrectly report `none` while localhost is reachable; pre-checking it
    // caused false QUEUED SOS states. We only queue when the HTTP request
    // genuinely times out or the network call throws.
    return await _triggerOnline(
      id: id, lat: resolvedLat, lng: resolvedLng,
      method: m, triggeredAt: triggeredAt,
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  GET POSITION — geolocator 12.0.0 API (desiredAccuracy)
  // ════════════════════════════════════════════════════════════════
  Future<Position?> _getPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return null;
      }

      // ✅ geolocator 12.0.0: use desiredAccuracy (not locationSettings)
      // ignore: deprecated_member_use
      return await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

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
          'triggered_at': triggeredAt.toUtc().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 8));

      final latencyMs =
          DateTime.now().difference(triggeredAt).inMilliseconds.toDouble();

      if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 202) {
        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {}

        final notified = (data['notified_contacts_count'] as num?)?.toInt() ?? 0;
        final total    = (data['total_contacts'] as num?)?.toInt() ?? 0;
        final fcmCount = (data['fcm_count'] as num?)?.toInt() ?? 0;
        final smsCount = (data['sms_count'] as num?)?.toInt() ?? 0;
        final dispatchStatus = (data['dispatch_status'] ?? data['status'] ?? 'received').toString();
        final serverAckMs = (data['server_ack_latency_ms'] as num?)?.toDouble();

        return SosResult(
          success: true,
          wasOffline: false,
          message: dispatchStatus == 'queued'
              ? 'Emergency signal received. Contact dispatch is queued.'
              : 'Alert sent. $notified of $total contacts notified.',
          messageBn: dispatchStatus == 'queued'
              ? 'জরুরি সংকেত গ্রহণ করা হয়েছে। Contact notification queue হয়েছে।'
              : (notified > 0
                  ? 'সংকেত পাঠানো হয়েছে! $notified জনকে জানানো হয়েছে।'
                  : 'সংকেত পাঠানো হয়েছে! Emergency contact যোগ করুন।'),
          latencyMs: serverAckMs ?? latencyMs,
          notifiedContactsCount: notified,
          totalContacts: total,
          sosId: data['sos_id']?.toString() ?? id,
          dispatchStatus: dispatchStatus,
          fcmCount: fcmCount,
          smsCount: smsCount,
          serverAckLatencyMs: serverAckMs,
        );
      }

      if (res.statusCode == 401) {
        return SosResult(
          success: false,
          wasOffline: false,
          message: 'Session expired. Please log in again.',
          messageBn: 'সেশন শেষ — আবার লগইন করুন',
        );
      }

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
      return SosResult(
        success: false,
        wasOffline: false,
        message: data['message']?.toString() ?? data['error']?.toString() ?? 'SOS server rejected the request.',
        messageBn: data['message_bn']?.toString() ?? 'SOS পাঠানো যায়নি — backend log দেখুন।',
        latencyMs: latencyMs,
        sosId: id,
      );
    } catch (_) {
      return await _queueOffline(
        id: id, lat: lat, lng: lng, method: method, triggeredAt: triggeredAt,
      );
    }
  }

  Future<SosResult> _queueOffline({
    required String id,
    required double lat,
    required double lng,
    required String method,
    required DateTime triggeredAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kQueueKey) ?? [];
    existing.add(jsonEncode({
      'id': id,
      'latitude': lat,
      'longitude': lng,
      'trigger_method': method,
      'triggered_at': triggeredAt.toUtc().toIso8601String(),
    }));
    await prefs.setStringList(_kQueueKey, existing);
    _watchConnectivity();

    return SosResult(
      success: true,
      wasOffline: true,
      message: 'Saved offline. Will send when connected.',
      messageBn: 'নেটওয়ার্ক নেই — সংরক্ষিত হয়েছে। সংযোগ পেলেই পাঠানো হবে।',
      sosId: id,
    );
  }

  Future<void> syncOfflineQueue() async {
    final token = await _auth.getToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kQueueKey) ?? [];
    if (raw.isEmpty) return;

    final payloads = raw
        .map((r) {
          try {
            return jsonDecode(r) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (payloads.isEmpty) {
      await prefs.remove(_kQueueKey);
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
        await prefs.remove(_kQueueKey);
      }
    } catch (_) {}
  }

  void _watchConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncOfflineQueue();
      }
    });
  }

  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kQueueKey) ?? []).length;
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}