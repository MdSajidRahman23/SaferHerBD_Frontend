import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  GOVERNMENT BD COLOR PALETTE  (from HTML design tokens)
// ════════════════════════════════════════════════════════════════
class AppColors {
  // Bangladesh greens
  static const g    = Color(0xFF006A4E);   // primary
  static const gl   = Color(0xFF008A65);   // light
  static const gd   = Color(0xFF004D38);   // dark
  static const gdd  = Color(0xFF003328);   // deepest

  // Bangladesh red
  static const r    = Color(0xFFF42A41);
  static const rl   = Color(0xFFFF4D61);
  static const rd   = Color(0xFFC41E32);

  // Accents
  static const gold   = Color(0xFFD4A017);
  static const purple = Color(0xFF7B5EA7);
  static const purpleD= Color(0xFF5B3F8A);
  static const orange = Color(0xFFE07B35);

  // Surfaces (light theme — matches HTML)
  static const bg      = Color(0xFFF0F4F1);
  static const surface = Color(0xFFFFFFFF);

  // Typography
  static const t1      = Color(0xFF1A2E25);   // primary text
  static const t2      = Color(0xFF4A6358);   // secondary
  static const t3      = Color(0xFF8AA496);   // muted

  // Border
  static const border  = Color(0xFFD8E8E2);

  // Aliases (for older references)
  static const green       = g;
  static const greenLight  = gl;
  static const greenDark   = gd;
  static const greenDeep   = gdd;
  static const red         = r;
  static const aqua        = Color(0xFF7FFFD4);
  static const bgDark      = Color(0xFF0A1A12);
  static const bgCard      = surface;
  static const bgCardLight = bg;
  static const textPrimary   = t1;
  static const textSecondary = t2;
  static const textMuted     = t3;
}

// ════════════════════════════════════════════════════════════════
//  PAID + FREE SERVICE CONFIG
//  ➜ Leave keys empty to use FREE tier
//  ➜ Add your key to switch to PAID tier
// ════════════════════════════════════════════════════════════════
class ServiceConfig {
  // ── Maps ────────────────────────────────────────────────────────
  // Free  : OpenStreetMap (no key needed)        ← default
  // Paid  : Google Maps                          ← needs API key
  static const String googleMapsApiKey = '';   // ← paste your key here when ready
  static bool get useGoogleMaps => googleMapsApiKey.isNotEmpty;

  // ── Geocoding ───────────────────────────────────────────────────
  // Free  : Nominatim (OpenStreetMap)            ← default
  // Paid  : Google Geocoding API                 ← uses Google Maps key
  static String get geocodingProvider => useGoogleMaps ? 'google' : 'nominatim';

  // ── Push Notifications ──────────────────────────────────────────
  // Free  : SSE polling (every 30s)              ← fallback
  // Paid  : Firebase FCM                         ← needs Firebase setup
  static const String firebaseServerKey = '';
  static bool get useFCM => firebaseServerKey.isNotEmpty;

  // ── SMS Fallback (when SOS contact has no FCM token) ────────────
  // Free  : Native SMS intent (uses user's SMS quota)   ← fallback
  // Paid  : Twilio                                       ← needs Twilio creds
  static const String twilioAccountSid = '';
  static const String twilioAuthToken  = '';
  static bool get useTwilio => twilioAccountSid.isNotEmpty && twilioAuthToken.isNotEmpty;

  // ── LLM Chatbot ─────────────────────────────────────────────────
  // Already configured server-side via .env GROQ_API_KEY (free tier works)
  // Backend automatically falls back to keyword-matched responses
}

// ════════════════════════════════════════════════════════════════
//  BACKEND API ENDPOINTS  (matched exactly to routes/api.php)
// ════════════════════════════════════════════════════════════════
class ApiConfig {
  static const baseUrl   = 'http://localhost:8000/api';
  static const mlBaseUrl = 'http://localhost:8001';

  // Auth
  static const loginUrl       = '$baseUrl/login';
  static const register       = '$baseUrl/register';

  // SOS
  static const sosTrigger     = '$baseUrl/sos/trigger';
  static const sosSyncOffline = '$baseUrl/sos/sync-offline';

  // Emergency Contacts
  static const contacts       = '$baseUrl/emergency-contacts';

  // Risk / Route
  static const riskPredict    = '$baseUrl/risk-engine/predict';
  static const routeSafest    = '$baseUrl/route/safest';

  // Forum
  static const forumPosts     = '$baseUrl/forum/posts';

  // Chatbot
  static const chatbot        = '$baseUrl/chat';

  // Public — no auth needed
  static const legalResources = '$baseUrl/legal-resources';
  static const safetyIndex    = '$baseUrl/safety-index';
}
