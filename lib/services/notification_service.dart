import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

/// Top-level handler required by FCM for background messages.
/// MUST be top-level (not inside a class).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in the background isolate if needed
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM bg] ${message.messageId}: ${message.notification?.title}');
}

/// NotificationService — manages FCM permission, token registration,
/// and local notification display when a push arrives in foreground.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _local = FlutterLocalNotificationsPlugin();
  final _api = ApiService();

  bool _initialized = false;

  // ───────────────────────────────────────────────────
  //  INITIALIZATION
  // ───────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1) Initialize Firebase
      await Firebase.initializeApp();

      // 2) Initialize local notifications (for foreground display)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _local.initialize(initSettings);

      // 3) Background handler must be set BEFORE requesting permission
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // 4) Request permission
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      // 5) Foreground message → show local notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6) Tap on notification (background) → could navigate
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[FCM tap] ${message.notification?.title}');
        // TODO: navigate to relevant screen via global navigator key
      });

      // 7) Get and register FCM token
      await registerToken();
    } catch (e) {
      debugPrint('[FCM] Init failed (will continue without push): $e');
    }
  }

  // ───────────────────────────────────────────────────
  //  TOKEN REGISTRATION (call after login too)
  // ───────────────────────────────────────────────────
  Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
      final ok = await _api.updateFcmToken(
        token,
        deviceType: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );
      if (!ok) debugPrint('[FCM] Token registration failed (user may not be logged in yet)');

      // Also listen for refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _api.updateFcmToken(newToken,
            deviceType: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
      });
    } catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }

  // ───────────────────────────────────────────────────
  //  FOREGROUND HANDLER
  // ───────────────────────────────────────────────────
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final isCritical = (message.data['type'] ?? '') == 'sos_dispatched' ||
                       (message.data['priority'] ?? '') == 'critical';

    final androidDetails = AndroidNotificationDetails(
      isCritical ? 'safeher_sos' : 'safeher_general',
      isCritical ? 'Emergency Alerts' : 'General Notifications',
      channelDescription: 'SafeHer notifications',
      importance: isCritical ? Importance.max : Importance.high,
      priority:   isCritical ? Priority.max     : Priority.high,
      playSound:  true,
      enableVibration: true,
      ticker: notification.title,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }
}
