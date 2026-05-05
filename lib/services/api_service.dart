import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  final _auth = AuthService();

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
      return await http.get(Uri.parse(url), headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return http.Response('{}', 503);
    }
  }

  Future<http.Response> _safePost(String url, Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      return await http.post(Uri.parse(url),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      return http.Response('{}', 503);
    }
  }

  // ── Safety Index (public) ────────────────────────────────────────
  Future<List<dynamic>> getSafetyIndex() async {
    final res = await _safeGet(ApiConfig.safetyIndex, auth: false);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] ?? body['cities'] ?? [];
    }
    return [];
  }

  // ── Emergency Contacts ───────────────────────────────────────────
  Future<List<dynamic>> getContacts() async {
    final res = await _safeGet(ApiConfig.contacts);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      // Backend returns { contacts: [...] }
      return body['contacts'] ?? body['data'] ?? [];
    }
    return [];
  }

  Future<bool> addContact({
    required String name, required String phone,
    required String relation, int priority = 1,
  }) async {
    final res = await _safePost(ApiConfig.contacts, {
      'name': name, 'phone': phone, 'relation': relation,
      'priority_order': priority,
      'notify_on_sos': true,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> deleteContact(String id) async {
    final res = await http.delete(Uri.parse('${ApiConfig.contacts}/$id'),
        headers: await _headers());
    return res.statusCode == 200;
  }

  // ── Risk / Route ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getAreaRisk({
    required double lat, required double lng, required String areaName,
  }) async {
    final res = await _safePost(ApiConfig.riskPredict, {
      'latitude': lat, 'longitude': lng, 'area_name_en': areaName,
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<Map<String, dynamic>?> getSafestRoute({
    required double startLat, required double startLng,
    required double endLat,   required double endLng,
  }) async {
    final res = await _safePost(ApiConfig.routeSafest, {
      'start': {'latitude': startLat, 'longitude': startLng},
      'end':   {'latitude': endLat,   'longitude': endLng},
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // ── Forum ────────────────────────────────────────────────────────
  Future<List<dynamic>> getForumPosts({int page = 1}) async {
    final res = await _safeGet('${ApiConfig.forumPosts}?page=$page');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['posts'] ?? body['data'] ?? [];
    }
    return [];
  }

  Future<bool> createPost(String content) async {
    final res = await _safePost(ApiConfig.forumPosts, {
      'content_body': content,
    });
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ── Chatbot ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> sendChatMessage(String message,
      {String? sessionId}) async {
    final body = <String, dynamic>{'message': message};
    if (sessionId != null) body['session_id'] = sessionId;

    final res = await _safePost(ApiConfig.chatbot, body);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // ── Legal Resources (public) ─────────────────────────────────────
  Future<List<dynamic>> getLegalResources() async {
    final res = await _safeGet(ApiConfig.legalResources, auth: false);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] ?? body['resources'] ?? [];
    }
    return [];
  }
}
