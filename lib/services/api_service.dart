import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

/// Central HTTP client for all SafeHer API calls.
/// Every method is failure-tolerant — returns null/empty/false on error
/// rather than throwing, so the UI never crashes.
class ApiService {
  final _auth = AuthService();

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _auth.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> _safeGet(String url, {bool auth = true, Duration? timeout}) async {
    try {
      return await http
          .get(Uri.parse(url), headers: await _headers(auth: auth))
          .timeout(timeout ?? const Duration(seconds: 10));
    } catch (_) {
      return http.Response('{"success":false,"message":"Network error"}', 503);
    }
  }

  Future<http.Response> _safePost(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
    Duration? timeout,
  }) async {
    try {
      return await http
          .post(Uri.parse(url),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(timeout ?? const Duration(seconds: 30));
    } catch (_) {
      return http.Response('{"success":false,"message":"Network error"}', 503);
    }
  }

  Future<http.Response> _safePut(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      return await http
          .put(Uri.parse(url),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      return http.Response('{"success":false,"message":"Network error"}', 503);
    }
  }

  Future<http.Response> _safeDelete(String url) async {
    try {
      return await http
          .delete(Uri.parse(url), headers: await _headers())
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return http.Response('{"success":false}', 503);
    }
  }

  Map<String, dynamic>? _parseJson(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  PROFILE
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getProfile() async {
    final res = await _safeGet(ApiConfig.profile);
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) return body['user'] as Map<String, dynamic>?;
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final res = await _safePut(ApiConfig.profile, data);
    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _safePost(ApiConfig.changePassword, {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    });
    return _parseJson(res) ?? {'success': false, 'message': 'Network error'};
  }

  Future<Map<String, dynamic>> changeEmergencyPin({
    required String currentPassword,
    required String newPin,
  }) async {
    final res = await _safePost(ApiConfig.changePin, {
      'current_password': currentPassword,
      'new_pin': newPin,
    });
    return _parseJson(res) ?? {'success': false, 'message': 'Network error'};
  }

  Future<bool> updateFcmToken(String token, {String deviceType = 'android'}) async {
    final res = await _safePost(ApiConfig.fcmToken, {
      'fcm_token': token,
      'device_type': deviceType,
    });
    return res.statusCode == 200;
  }

  // ═══════════════════════════════════════════════════════════
  //  SAFETY INDEX  (public)
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getSafetyIndex() async {
    final res = await _safeGet(ApiConfig.safetyIndex, auth: false);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) {
      return (body['data'] ?? body['cities'] ?? []) as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>?> getCitySafety(String city) async {
    final res = await _safeGet('${ApiConfig.safetyIndex}/$city', auth: false);
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) {
      return body['city'] as Map<String, dynamic>?;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  RECENT ALERTS  (public)
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getRecentAlerts({
    double? lat,
    double? lng,
    double radiusKm = 10,
    int limit = 10,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'radius_km': '$radiusKm',
    };
    if (lat != null && lng != null) {
      params['lat'] = '$lat';
      params['lng'] = '$lng';
    }
    final uri = Uri.parse(ApiConfig.recentAlerts).replace(queryParameters: params);
    final res = await _safeGet(uri.toString(), auth: false);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['alerts'] ?? []) as List<dynamic>;
    return [];
  }

  // ═══════════════════════════════════════════════════════════
  //  GEOCODING  (public)
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> geocode(String query) async {
    final uri = Uri.parse(ApiConfig.geocode).replace(queryParameters: {
      'q': query,
      'limit': '5',
    });
    final res = await _safeGet(uri.toString(), auth: false, timeout: const Duration(seconds: 10));
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['results'] ?? []) as List<dynamic>;
    return [];
  }

  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse(ApiConfig.reverseGeocode).replace(queryParameters: {
      'lat': '$lat',
      'lng': '$lng',
    });
    final res = await _safeGet(uri.toString(), auth: false);
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) {
      return body['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  EMERGENCY CONTACTS
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getContacts() async {
    final res = await _safeGet(ApiConfig.contacts);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['contacts'] ?? body['data'] ?? []) as List<dynamic>;
    return [];
  }

  Future<Map<String, dynamic>> addContact({
    required String name,
    required String phone,
    String relation = 'Contact',
    int priority = 1,
  }) async {
    final res = await _safePost(ApiConfig.contacts, {
      'name': name,
      'phone': phone,
      'relation': relation.isEmpty ? 'Contact' : relation,
      'priority_order': priority,
      'notify_on_sos': true,
    });
    final body = _parseJson(res) ?? {};
    body['statusCode'] = res.statusCode;
    return body;
  }

  Future<bool> updateContact(String id, Map<String, dynamic> data) async {
    final res = await _safePut('${ApiConfig.contacts}/$id', data);
    return res.statusCode == 200;
  }

  Future<bool> deleteContact(String id) async {
    if (id.isEmpty) return false;
    final res = await _safeDelete('${ApiConfig.contacts}/$id');
    return res.statusCode == 200;
  }

  // ═══════════════════════════════════════════════════════════
  //  RISK / ROUTE
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getAreaRisk({
    required double lat,
    required double lng,
    required String areaName,
  }) async {
    final res = await _safePost(ApiConfig.riskPredict, {
      'latitude': lat,
      'longitude': lng,
      'area_name_en': areaName,
    });
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) return body;
    return null;
  }

  Future<Map<String, dynamic>?> getSafestRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String travelMode = 'foot-walking',
  }) async {
    final res = await _safePost(ApiConfig.routeSafest, {
      'start': {'latitude': startLat, 'longitude': startLng},
      'end':   {'latitude': endLat,   'longitude': endLng},
      'travel_mode': travelMode,
    });
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) return body;
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  SOS HISTORY
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getSosHistory() async {
    final res = await _safeGet(ApiConfig.sosHistory);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['alerts'] ?? []) as List<dynamic>;
    return [];
  }

  Future<bool> trackLocation({
    required String sosId,
    required double lat,
    required double lng,
    double? speedKmh,
  }) async {
    final res = await _safePost(ApiConfig.sosTrack(sosId), {
      'latitude': lat,
      'longitude': lng,
      if (speedKmh != null) 'speed_kmh': speedKmh,
    });
    return res.statusCode == 200;
  }

  // ═══════════════════════════════════════════════════════════
  //  FORUM
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getForumPosts({int page = 1}) async {
    final res = await _safeGet('${ApiConfig.forumPosts}?page=$page');
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['posts'] ?? body['data'] ?? []) as List<dynamic>;
    return [];
  }

  Future<Map<String, dynamic>> createPost(String content, {List<String>? tags}) async {
    final res = await _safePost(ApiConfig.forumPosts, {
      'content_body': content,
      if (tags != null && tags.isNotEmpty) 'tags_json': tags,
    });
    final body = _parseJson(res) ?? {};
    body['statusCode'] = res.statusCode;
    return body;
  }

  Future<bool> deletePost(String postId) async {
    final res = await _safeDelete('${ApiConfig.forumPosts}/$postId');
    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    final res = await _safePost('${ApiConfig.forumPosts}/$postId/like', {});
    final body = _parseJson(res) ?? {};
    body['statusCode'] = res.statusCode;
    return body;
  }

  Future<Map<String, dynamic>> replyToPost(String postId, String replyText) async {
    final res = await _safePost('${ApiConfig.forumPosts}/$postId/reply', {
      'reply_text': replyText,
    });
    final body = _parseJson(res) ?? {};
    body['statusCode'] = res.statusCode;
    return body;
  }

  Future<List<dynamic>> getReplies(String postId) async {
    final res = await _safeGet('${ApiConfig.forumPosts}/$postId/replies');
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['replies'] ?? []) as List<dynamic>;
    return [];
  }

  Future<bool> reportPost(String postId, String reason) async {
    final res = await _safePost('${ApiConfig.forumPosts}/$postId/report', {
      'reason_text': reason,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ═══════════════════════════════════════════════════════════
  //  CHATBOT
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> sendChatMessage(
    String message, {
    String? sessionId,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (sessionId != null) body['session_id'] = sessionId;
    final res = await _safePost(ApiConfig.chatbot, body, timeout: const Duration(seconds: 45));
    final json = _parseJson(res);
    if (res.statusCode == 200 && json != null) return json;
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  LEGAL RESOURCES (public)
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getLegalResources() async {
    final res = await _safeGet(ApiConfig.legalResources, auth: false);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['resources'] ?? body['data'] ?? []) as List<dynamic>;
    return [];
  }

  // ═══════════════════════════════════════════════════════════
  //  NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getNotifications() async {
    final res = await _safeGet(ApiConfig.notifications);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['notifications'] ?? []) as List<dynamic>;
    return [];
  }

  Future<int> getUnreadNotificationCount() async {
    final res = await _safeGet(ApiConfig.notificationsUnread);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['unread_count'] as int?) ?? 0;
    return 0;
  }

  Future<bool> markNotificationRead(String id) async {
    final res = await _safePost('${ApiConfig.notifications}/$id/read', {});
    return res.statusCode == 200;
  }

  Future<bool> markAllNotificationsRead() async {
    final res = await _safePost(ApiConfig.notificationsReadAll, {});
    return res.statusCode == 200;
  }

  Future<bool> deleteNotification(String id) async {
    final res = await _safeDelete('${ApiConfig.notifications}/$id');
    return res.statusCode == 200;
  }
}
