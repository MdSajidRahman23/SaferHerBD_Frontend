import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class AuthService {
  static const _kToken = 'sh_token';
  static const _kUser  = 'sh_user';

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 12));

      final data = _safeJson(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final token = (data['token'] ?? data['access_token'])?.toString();
        final user  = data['user'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kToken, token);
          if (user != null) await prefs.setString(_kUser, jsonEncode(user));
        }
        return {'success': true, 'user': user, 'token': token};
      }
      return {
        'success': false,
        'message': data['message']?.toString() ?? 'Invalid credentials',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final data = _safeJson(res.body);

      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        final token = (data['token'] ?? data['access_token'])?.toString();
        final user  = data['user'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kToken, token);
          if (user != null) await prefs.setString(_kUser, jsonEncode(user));
        }
        return {'success': true, 'user': user, 'token': token};
      }

      return {
        'success': false,
        'message': data['message']?.toString()
            ?? _firstValidationError(data)
            ?? 'Registration failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse(ApiConfig.logoutUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {/* ignore */}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> refreshUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final res = await http.get(
        Uri.parse(ApiConfig.userUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = _safeJson(res.body);
        final user = data.containsKey('user') ? data['user'] : data;
        if (user is Map<String, dynamic>) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kUser, jsonEncode(user));
          return user;
        }
      }
    } catch (_) {
      // Keep cached user on network errors.
    }
    return getUser();
  }

  Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String? _firstValidationError(Map<String, dynamic> data) {
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstField = errors.values.first;
      if (firstField is List && firstField.isNotEmpty) return firstField.first.toString();
    }
    return null;
  }
}