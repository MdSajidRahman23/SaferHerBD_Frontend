import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  COLOR TOKENS — exactly matching design CSS variables
// ═══════════════════════════════════════════════════════════════
class AppColors {
  // Bangladesh brand
  static const green     = Color(0xFF006A4E);
  static const greenDeep = Color(0xFF004B37);
  static const greenSoft = Color(0xFFE6F2EE);

  static const red     = Color(0xFFF42A41);
  static const redSoft = Color(0xFFFEE7EA);

  // Surfaces
  static const bg     = Color(0xFFF8FAFC);
  static const card   = Color(0xFFFFFFFF);
  static const page   = Color(0xFFEEF1F4);
  static const dark   = Color(0xFF0B1220);

  // Text
  static const ink   = Color(0xFF0B1220);
  static const ink2  = Color(0xFF475569);
  static const ink3  = Color(0xFF94A3B8);
  static const line  = Color(0xFFE2E8F0);

  // Accents
  static const amber = Color(0xFFF59E0B);
  static const blue  = Color(0xFF0E5C8B);

  // Map dark variants
  static const mapBase    = Color(0xFF0E1726);
  static const mapRiver   = Color(0xFF1E3A5F);
  static const mapRiverHi = Color(0xFF2C5282);

  // ── Backward-compat aliases (used by old screens) ──
  static const g    = green;
  static const gd   = greenDeep;
  static const gdd  = Color(0xFF003328);
  static const gl   = Color(0xFF008A65);
  static const r    = red;
  static const rl   = Color(0xFFFF4D61);
  static const rd   = Color(0xFFC41E32);
  static const t1   = ink;
  static const t2   = ink2;
  static const t3   = ink3;
  static const surface = card;
  static const border  = line;
  static const aqua    = Color(0xFF7FFFD4);
  static const gold    = amber;
  static const purple  = Color(0xFF7B5EA7);
  static const orange  = Color(0xFFE07B35);
  static const greenLight  = gl;
  static const greenDark   = gd;
  static const greenDeeper = gdd;
}


// ═══════════════════════════════════════════════════════════════
//  API CONFIG — environment-aware URL handling
// ═══════════════════════════════════════════════════════════════
//
// Build with custom URL:
//   flutter run --dart-define=API_BASE_URL=https://api.safeher.bd/api
//
// Defaults:
//   • Android emulator: http://10.0.2.2:8000/api  (host loopback alias)
//   • iOS simulator:    http://127.0.0.1:8000/api
//   • Web (Chrome):     http://127.0.0.1:8000/api
//   • Real device:      MUST set API_BASE_URL via --dart-define
//
class ApiConfig {
  static const String _customBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const String _customMlBaseUrl =
      String.fromEnvironment('ML_API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;

    if (kIsWeb) return 'http://127.0.0.1:8000/api';

    // Android emulator → 10.0.2.2 maps to host 127.0.0.1
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static String get mlBaseUrl {
    if (_customMlBaseUrl.isNotEmpty) return _customMlBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8001';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    }
    return 'http://127.0.0.1:8001';
  }

  // ─────── Auth ───────
  static String get loginUrl    => '$baseUrl/login';
  static String get register    => '$baseUrl/register';
  static String get logoutUrl   => '$baseUrl/logout';
  static String get userUrl     => '$baseUrl/user';

  // ─────── Profile ───────
  static String get profile          => '$baseUrl/profile';
  static String get changePassword   => '$baseUrl/profile/change-password';
  static String get changePin        => '$baseUrl/profile/change-pin';
  static String get fcmToken         => '$baseUrl/user/fcm-token';

  // ─────── SOS ───────
  static String get sosTrigger       => '$baseUrl/sos/trigger';
  static String get sosSyncOffline   => '$baseUrl/sos/sync-offline';
  static String get sosHistory       => '$baseUrl/sos/history';
  static String sosTrack(String id)  => '$baseUrl/sos/$id/track';

  // ─────── Contacts ───────
  static String get contacts         => '$baseUrl/emergency-contacts';

  // ─────── Risk / Route ───────
  static String get riskPredict      => '$baseUrl/risk-engine/predict';
  static String get routeSafest      => '$baseUrl/route/safest';

  // ─────── Forum ───────
  static String get forumPosts       => '$baseUrl/forum/posts';

  // ─────── Chatbot ───────
  static String get chatbot          => '$baseUrl/chat';

  // ─────── Public resources ───────
  static String get legalResources   => '$baseUrl/legal-resources';
  static String get safetyIndex      => '$baseUrl/safety-index';
  static String get recentAlerts     => '$baseUrl/recent-alerts';
  static String get geocode          => '$baseUrl/geocode';
  static String get reverseGeocode   => '$baseUrl/geocode/reverse';

  // ─────── Notifications ───────
  static String get notifications        => '$baseUrl/notifications';
  static String get notificationsUnread  => '$baseUrl/notifications/unread-count';
  static String get notificationsReadAll => '$baseUrl/notifications/read-all';
}


// ═══════════════════════════════════════════════════════════════
//  EXTERNAL SERVICES CONFIG
// ═══════════════════════════════════════════════════════════════
class ServiceConfig {
  // Set with: --dart-define=ORS_API_KEY=...
  static const String orsApiKey =
      String.fromEnvironment('ORS_API_KEY', defaultValue: '');

  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_KEY', defaultValue: '');

  static bool get useGoogleMaps => googleMapsApiKey.isNotEmpty;
  static bool get hasOrsKey     => orsApiKey.isNotEmpty;

  // Important crisis helplines (Bangladesh)
  static const String helpline109     = '109';   // Women & Child Helpline
  static const String helpline999     = '999';   // National Emergency
  static const String kaanPeteRoi     = '9612119911'; // Mental health
}
