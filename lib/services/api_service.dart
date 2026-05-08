import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  final _auth = AuthService();

  // ────────────────────────────────────────────────────────────────
  //  HELPERS
  // ────────────────────────────────────────────────────────────────
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

  Future<http.Response> _safeGet(String url, {bool auth = true}) async {
    try {
      return await http
          .get(Uri.parse(url), headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return http.Response('{"success":false,"message":"Network error"}', 503);
    }
  }

  Future<http.Response> _safePost(String url, Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      return await http
          .post(Uri.parse(url),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      return http.Response('{"success":false,"message":"Network error"}', 503);
    }
  }

  Map<String, dynamic>? _parseJson(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────
  //  SAFETY INDEX (public)
  // ────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getSafetyIndex() async {
    final res = await _safeGet(ApiConfig.safetyIndex, auth: false);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) {
      return body['data'] ?? body['cities'] ?? [];
    }
    return [];
  }

  // ────────────────────────────────────────────────────────────────
  //  EMERGENCY CONTACTS
  // ────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getContacts() async {
    final res = await _safeGet(ApiConfig.contacts);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) {
      return body['contacts'] ?? body['data'] ?? [];
    }
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

  Future<bool> deleteContact(String id) async {
    if (id.isEmpty) return false;
    try {
      final res = await http
          .delete(Uri.parse('${ApiConfig.contacts}/$id'),
              headers: await _headers())
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────
  //  RISK / ROUTE
  // ────────────────────────────────────────────────────────────────
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
      'end': {'latitude': endLat, 'longitude': endLng},
      'travel_mode': travelMode,
    });
    final body = _parseJson(res);
    if (res.statusCode == 200 && body != null) return body;
    return null;
  }

  // ────────────────────────────────────────────────────────────────
  //  FORUM
  // ────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getForumPosts({int page = 1}) async {
    final res = await _safeGet('${ApiConfig.forumPosts}?page=$page');
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) {
      return body['posts'] ?? body['data'] ?? [];
    }
    return [];
  }

  Future<Map<String, dynamic>> createPost(String content,
      {List<String>? tags}) async {
    final res = await _safePost(ApiConfig.forumPosts, {
      'content_body': content,
      if (tags != null && tags.isNotEmpty) 'tags_json': tags,
    });
    final body = _parseJson(res) ?? {};
    body['statusCode'] = res.statusCode;
    return body;
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
    if (res.statusCode == 200) {
      return body['replies'] ?? [];
    }
    return [];
  }

  Future<bool> reportPost(String postId, String reason) async {
    final res = await _safePost('${ApiConfig.forumPosts}/$postId/report', {
      'reason_text': reason,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ────────────────────────────────────────────────────────────────
  //  CHATBOT
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> sendChatMessage(String message,
      {String? sessionId}) async {
    final body = <String, dynamic>{'message': message};
    if (sessionId != null) body['session_id'] = sessionId;

    final res = await _safePost(ApiConfig.chatbot, body);
    final json = _parseJson(res);
    if (res.statusCode == 200 && json != null) return json;
    return null;
  }

  // ────────────────────────────────────────────────────────────────
  //  LEGAL RESOURCES (public)
  // ────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getLegalResources() async {
    final res = await _safeGet(ApiConfig.legalResources, auth: false);
    final body = _parseJson(res) ?? {};
    if (res.statusCode == 200) {
      return body['resources'] ?? body['data'] ?? [];
    }
    return [];
  }
}
