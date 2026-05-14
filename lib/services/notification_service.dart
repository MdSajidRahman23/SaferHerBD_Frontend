import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

/// NotificationService — handles local notifications and (optionally) FCM.
///
/// FCM is OPTIONAL. If Firebase is not configured (no firebase_options.dart),
/// this service silently disables FCM but keeps local notifications working,
/// so the app never crashes at startup.
class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _local = FlutterLocalNotificationsPlugin();
  final _api = ApiService();

  bool _initialized = false;
  bool _fcmEnabled = false;
  String? _fcmToken;

  /// ⭐ Primary entry point — what main.dart calls.
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // ── Local notifications ──────────────────────────────────
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _local.initialize(
        settings,
        onDidReceiveNotificationResponse: (resp) {
          debugPrint('[Notif] Tapped: ${resp.payload}');
        },
      );
      debugPrint('[Notif] ✅ Local notifications ready');
    } catch (e) {
      debugPrint('[Notif] ⚠️ Local init failed: $e');
    }

    // ── FCM (optional) ──────────────────────────────────────
    await _tryInitFcm();
  }

  /// Alias for backwards compat (some code calls .init() instead of .initialize())
  Future<void> init() => initialize();

  Future<void> _tryInitFcm() async {
    try {
      final available = await _checkFirebaseAvailable();
      if (!available) {
        throw Exception('Firebase not configured');
      }
      // Uncomment after running `flutterfire configure`:
      //
      //   await Firebase.initializeApp(
      //     options: DefaultFirebaseOptions.currentPlatform,
      //   );
      //   final messaging = FirebaseMessaging.instance;
      //   await messaging.requestPermission();
      //   _fcmToken = await messaging.getToken();
      //
      _fcmEnabled = true;
      debugPrint('[Notif] ✅ FCM ready, token: $_fcmToken');
    } catch (e) {
      _fcmEnabled = false;
      debugPrint('[Notif] ⚠️ FCM disabled: $e');
    }
  }

  Future<bool> _checkFirebaseAvailable() async {
    // Without dynamic imports, default to false. The real Firebase
    // init will throw if files are missing — caught above.
    return false;
  }

  /// Register the FCM token with the backend.
  Future<void> registerToken() async {
    if (!_fcmEnabled || _fcmToken == null) return;
    try {
      await _api.updateFcmToken(_fcmToken!);
      debugPrint('[Notif] ✅ Token registered');
    } catch (e) {
      debugPrint('[Notif] ⚠️ Token registration failed: $e');
    }
  }

  /// Show a local notification.
  Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'safeher_default',
        'SafeHer Notifications',
        channelDescription: 'SOS confirmations and safety alerts',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _local.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[Notif] showLocal failed: $e');
    }
  }

  bool get fcmEnabled => _fcmEnabled;
  String? get fcmToken => _fcmToken;
}