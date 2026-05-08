import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  COLOR TOKENS — exactly matching design CSS variables
// ════════════════════════════════════════════════════════════════
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

  // ── Backward-compat aliases (used by old screens) ─────────────
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

// ════════════════════════════════════════════════════════════════
//  API CONFIG  (matched to Laravel routes)
// ════════════════════════════════════════════════════════════════
class ApiConfig {
  static const baseUrl   = 'http://127.0.0.1:8000/api';
  static const mlBaseUrl = 'http://127.0.0.1:8001';

  static const loginUrl       = '$baseUrl/login';
  static const register       = '$baseUrl/register';
  static const userUrl        = '$baseUrl/user';
  static const fcmToken       = '$baseUrl/user/fcm-token';

  static const sosTrigger     = '$baseUrl/sos/trigger';
  static const sosSyncOffline = '$baseUrl/sos/sync-offline';

  static const contacts       = '$baseUrl/emergency-contacts';

  static const riskPredict    = '$baseUrl/risk-engine/predict';
  static const routeSafest    = '$baseUrl/route/safest';

  static const forumPosts     = '$baseUrl/forum/posts';

  static const chatbot        = '$baseUrl/chat';

  static const legalResources = '$baseUrl/legal-resources';
  static const safetyIndex    = '$baseUrl/safety-index';
}

// ════════════════════════════════════════════════════════════════
//  PAID + FREE service config
// ════════════════════════════════════════════════════════════════
class ServiceConfig {
  static const String googleMapsApiKey = '';
  static bool get useGoogleMaps => googleMapsApiKey.isNotEmpty;

  static const String firebaseServerKey = '';
  static bool get useFCM => firebaseServerKey.isNotEmpty;
}
