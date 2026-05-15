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
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return null;
    }
  }


  List<dynamic> _extractList(Map<String, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key];
      if (value is List) return value;
      if (value is Map<String, dynamic>) {
        final nested = value['data'] ?? value['items'] ?? value['results'];
        if (nested is List) return nested;
      }
    }
    final data = body['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['items'] ?? data['results'];
      if (nested is List) return nested;
    }
    return [];
  }

  Map<String, dynamic>? _extractMap(Map<String, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String? _firstValidationError(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  PROFILE
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getProfile() async {
    final res = await _safeGet(ApiConfig.profile);
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) {
      return _extractMap(body, ['user', 'data']) ?? body;
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfileDetailed(Map<String, dynamic> data) async {
    final res = await _safePut(ApiConfig.profile, data);
    final body = _parseJson(res) ?? {};

    if (res.statusCode == 200 && body['success'] != false) {
      final user = _extractMap(body, ['user', 'data']);
      if (user != null) {
        // Keep the locally cached /api/user data fresh after profile edits.
        await _auth.refreshUser();
      }
      return {
        'success': true,
        'message': body['message']?.toString() ?? 'Profile updated',
        'user': user,
      };
    }

    return {
      'success': false,
      'message': body['message']?.toString() ?? _firstValidationError(body) ?? 'Update failed',
    };
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final result = await updateProfileDetailed(data);
    return result['success'] == true;
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
      return _extractList(body, ['cities', 'data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getCitySafety(String city) async {
    final res = await _safeGet('${ApiConfig.safetyIndex}/$city', auth: false);
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) {
      return _extractMap(body, ['city', 'data']);
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
    if (res.statusCode == 200) return _extractList(body, ['alerts', 'data']);
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
    if (res.statusCode == 200) return _extractList(body, ['results', 'data']);
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
      return _extractMap(body, ['data', 'result', 'address']) ?? body;
    }
    return null;
  }

  Future<List<dynamic>> getNearbySafePlaces({
    required double lat,
    required double lng,
    int radiusMeters = 1800,
  }) async {
    final uri = Uri.parse(ApiConfig.safePlacesNearby).replace(queryParameters: {
      'lat': '$lat',
      'lng': '$lng',
      'radius_m': '$radiusMeters',
    });
    final res = await _safeGet(uri.toString(), timeout: const Duration(seconds: 15));
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return _extractList(body, ['places', 'data']);
    return [];
  }

  // ═══════════════════════════════════════════════════════════
  //  EMERGENCY CONTACTS
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getContacts() async {
    final res = await _safeGet(ApiConfig.contacts);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return _extractList(body, ['contacts', 'data']);
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

  Future<Map<String, dynamic>> createContactResult(Map<String, dynamic> data) async {
    final res = await _safePost(ApiConfig.contacts, {
      'name': data['name'],
      'phone': data['phone'],
      'relation': data['relation'] ?? 'Contact',
      'priority_order': data['priority_order'],
      'notify_on_sos': data['notify_on_sos'] ?? true,
      'notify_on_safe_arrival': data['notify_on_safe_arrival'] ?? false,
    });
    final body = _parseJson(res) ?? {};

    if (res.statusCode == 200 || res.statusCode == 201) {
      final contact = _extractMap(body, ['contact', 'data']) ?? body;
      return {
        'success': true,
        'message': body['message']?.toString() ?? 'Contact saved',
        'contact': contact,
      };
    }

    return {
      'success': false,
      'message': body['message']?.toString() ?? _firstValidationError(body) ?? 'Could not save contact',
    };
  }

  Future<Map<String, dynamic>?> createContact(Map<String, dynamic> data) async {
    final result = await createContactResult(data);
    return result['success'] == true ? result['contact'] as Map<String, dynamic>? : null;
  }

  Future<Map<String, dynamic>> updateContactResult(String id, Map<String, dynamic> data) async {
    final res = await _safePut('${ApiConfig.contacts}/$id', data);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) {
      return {
        'success': true,
        'message': body['message']?.toString() ?? 'Contact updated',
        'contact': _extractMap(body, ['contact', 'data']) ?? body,
      };
    }
    return {
      'success': false,
      'message': body['message']?.toString() ?? _firstValidationError(body) ?? 'Could not update contact',
    };
  }

  Future<bool> updateContact(String id, Map<String, dynamic> data) async {
    final result = await updateContactResult(id, data);
    return result['success'] == true;
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
    String? routeProfile,
    String? vehicleType,
    String? modeLabel,
    String? routePreference,
    int? safeStopCount,
  }) async {
    final payload = <String, dynamic>{
      'start': {'latitude': startLat, 'longitude': startLng},
      'end': {'latitude': endLat, 'longitude': endLng},
      'travel_mode': travelMode,
      if (routeProfile != null && routeProfile.trim().isNotEmpty) 'route_profile': routeProfile.trim(),
      if (vehicleType != null && vehicleType.trim().isNotEmpty) 'vehicle_type': vehicleType.trim(),
      if (modeLabel != null && modeLabel.trim().isNotEmpty) 'mode_label': modeLabel.trim(),
      if (routePreference != null && routePreference.trim().isNotEmpty) 'route_preference': routePreference.trim(),
      if (safeStopCount != null) 'safe_stop_count': safeStopCount,
    };

    final res = await _safePost(ApiConfig.routeSafest, payload);
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) return body;
    return null;
  }

  Future<Map<String, dynamic>> reportRouteIssue({
    required String reportType,
    required double latitude,
    required double longitude,
    String? severity,
    String? note,
    String? routeId,
    String? travelMode,
    String? routePreference,
  }) async {
    final res = await _safePost(ApiConfig.routeReports, {
      'report_type': reportType,
      'latitude': latitude,
      'longitude': longitude,
      if (severity != null && severity.trim().isNotEmpty) 'severity': severity.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (routeId != null && routeId.trim().isNotEmpty) 'route_id': routeId.trim(),
      if (travelMode != null && travelMode.trim().isNotEmpty) 'travel_mode': travelMode.trim(),
      if (routePreference != null && routePreference.trim().isNotEmpty) 'route_preference': routePreference.trim(),
    });
    final body = _parseJson(res) ?? {};
    body['statusCode'] = res.statusCode;
    return {
      'success': res.statusCode == 200 || res.statusCode == 201,
      'message': body['message']?.toString() ?? (res.statusCode == 201 ? 'Report saved' : 'Could not save report'),
      'data': body,
    };
  }


  // ═══════════════════════════════════════════════════════════
  //  JOURNEY SAFETY MODE
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getActiveJourneySafety() async {
    final res = await _safeGet(ApiConfig.journeyActive);
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) {
      return _extractMap(body, ['journey', 'data']);
    }
    return null;
  }

  Future<Map<String, dynamic>> startJourneySafety({
    required double startLat,
    required double startLng,
    double? endLat,
    double? endLng,
    String? startLabel,
    String? endLabel,
    String? routeLabel,
    String? travelMode,
    String? routePreference,
    int? safetyScore,
    int? expectedDurationMin,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await _safePost(ApiConfig.journeyStart, {
      'start_latitude': startLat,
      'start_longitude': startLng,
      if (endLat != null) 'end_latitude': endLat,
      if (endLng != null) 'end_longitude': endLng,
      if (startLabel != null && startLabel.trim().isNotEmpty) 'start_label': startLabel.trim(),
      if (endLabel != null && endLabel.trim().isNotEmpty) 'end_label': endLabel.trim(),
      if (routeLabel != null && routeLabel.trim().isNotEmpty) 'route_label': routeLabel.trim(),
      if (travelMode != null && travelMode.trim().isNotEmpty) 'travel_mode': travelMode.trim(),
      if (routePreference != null && routePreference.trim().isNotEmpty) 'route_preference': routePreference.trim(),
      if (safetyScore != null) 'safety_score': safetyScore,
      if (expectedDurationMin != null && expectedDurationMin > 0) 'expected_duration_min': expectedDurationMin,
      if (metadata != null) 'metadata': metadata,
    });
    final body = _parseJson(res) ?? {};
    return {
      'success': res.statusCode >= 200 && res.statusCode < 300 && body['success'] != false,
      'message': body['message']?.toString() ?? 'Journey safety response received',
      'journey': _extractMap(body, ['journey', 'data']),
      'statusCode': res.statusCode,
    };
  }

  Future<Map<String, dynamic>> checkInJourneySafety({
    required String journeyId,
    String status = 'safe',
    double? latitude,
    double? longitude,
    String? note,
    int? batteryLevel,
  }) async {
    final res = await _safePost(ApiConfig.journeyCheckIn(journeyId), {
      'status': status,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (batteryLevel != null) 'battery_level': batteryLevel,
    });
    final body = _parseJson(res) ?? {};
    return {
      'success': res.statusCode >= 200 && res.statusCode < 300 && body['success'] != false,
      'message': body['message']?.toString() ?? 'Journey check-in saved',
      'journey': _extractMap(body, ['journey', 'data']),
      'statusCode': res.statusCode,
    };
  }

  Future<Map<String, dynamic>> completeJourneySafety(String journeyId) async {
    final res = await _safePost(ApiConfig.journeyComplete(journeyId), {});
    final body = _parseJson(res) ?? {};
    return {
      'success': res.statusCode >= 200 && res.statusCode < 300 && body['success'] != false,
      'message': body['message']?.toString() ?? 'Journey completed',
      'journey': _extractMap(body, ['journey', 'data']),
      'statusCode': res.statusCode,
    };
  }

  Future<Map<String, dynamic>> cancelJourneySafety(String journeyId) async {
    final res = await _safePost(ApiConfig.journeyCancel(journeyId), {});
    final body = _parseJson(res) ?? {};
    return {
      'success': res.statusCode >= 200 && res.statusCode < 300 && body['success'] != false,
      'message': body['message']?.toString() ?? 'Journey cancelled',
      'journey': _extractMap(body, ['journey', 'data']),
      'statusCode': res.statusCode,
    };
  }

  // ═══════════════════════════════════════════════════════════
  //  SOS HISTORY
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getSosHistory() async {
    final res = await _safeGet(ApiConfig.sosHistory);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return _extractList(body, ['alerts', 'data']);
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


  Future<Map<String, dynamic>> resolveSos({
    required String sosId,
    String? note,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _safePost(ApiConfig.sosResolve(sosId), {
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final body = _parseJson(res) ?? {};
    body['statusCode'] = res.statusCode;
    return {
      'success': res.statusCode >= 200 && res.statusCode < 300 && body['success'] != false,
      'message': body['message']?.toString() ?? 'Safety check saved',
      'data': body,
    };
  }

  Future<Map<String, dynamic>> escalateSos({
    required String sosId,
    String? reason,
    String? note,
    int? level,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _safePost(ApiConfig.sosEscalate(sosId), {
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (level != null) 'level': level,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final body = _parseJson(res) ?? {};
    body['statusCode'] = res.statusCode;
    return {
      'success': res.statusCode >= 200 && res.statusCode < 300 && body['success'] != false,
      'message': body['message']?.toString() ?? 'SOS escalation updated',
      'data': body,
      'recommended_actions': _extractList(body, ['recommended_actions', 'actions']),
    };
  }

  Future<List<dynamic>> getSosTimeline(String sosId) async {
    final res = await _safeGet(ApiConfig.sosTimeline(sosId));
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return _extractList(body, ['events', 'data']);
    return [];
  }

  // ═══════════════════════════════════════════════════════════
  //  FORUM
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getForumPosts({int page = 1}) async {
    final res = await _safeGet('${ApiConfig.forumPosts}?page=$page');
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return _extractList(body, ['posts', 'data']);
    return [];
  }

  Future<Map<String, dynamic>> createPost(
    String content, {
    String? tag,
    List<String>? tags,
  }) async {
    final tagList = <String>[];
    if (tag != null && tag.trim().isNotEmpty) tagList.add(tag.trim());
    if (tags != null) tagList.addAll(tags.where((t) => t.trim().isNotEmpty));

    final res = await _safePost(ApiConfig.forumPosts, {
      'content_body': content,
      if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
      if (tagList.isNotEmpty) 'tags_json': tagList,
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
    if (res.statusCode == 200) return _extractList(body, ['replies', 'data']);
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
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      body['session_id'] = sessionId.trim();
    }
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }
    final res = await _safePost(ApiConfig.chatbot, body, timeout: const Duration(seconds: 45));
    final json = _parseJson(res) ?? <String, dynamic>{};
    json['statusCode'] = res.statusCode;
    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    return json;
  }

  // ═══════════════════════════════════════════════════════════
  //  LEGAL RESOURCES (public)
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getLegalResources() async {
    final res = await _safeGet(ApiConfig.legalResources, auth: false);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return _extractList(body, ['resources', 'data']);
    return [];
  }

  // ═══════════════════════════════════════════════════════════
  //  NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════
  Future<List<dynamic>> getNotifications() async {
    final res = await _safeGet(ApiConfig.notifications);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return _extractList(body, ['notifications', 'data']);
    return [];
  }

  Future<int> getUnreadNotificationCount() async {
    final res = await _safeGet(ApiConfig.notificationsUnread);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) return (body['unread_count'] as num?)?.toInt() ?? 0;
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