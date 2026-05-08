import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  // ────────────────────────────────────────────────────────────────
  //  LOGIN
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String phone, String password) async {
    if (phone.trim().isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Please enter both phone and password'};
    }

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone': phone.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 12));

      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': false, 'message': 'Server returned invalid response'};
      }

      final token = data['access_token'] as String?;
      if ((res.statusCode == 200 || res.statusCode == 201) && token != null) {
        await _saveToken(token);
        if (data['user'] != null) {
          await _saveUser(data['user']);
        } else {
          await _saveUser({'phone': phone.trim()});
        }
        data['token'] = token;
        data['success'] = true;
      } else {
        if (res.statusCode == 401) {
          data['message'] = data['message'] ?? 'Phone or password is incorrect';
        } else if (res.statusCode == 422) {
          data['message'] = _firstValidationError(data) ?? 'Invalid input';
        } else if (res.statusCode == 500) {
          data['message'] = 'Server error. Please try again.';
        }
        data['success'] = false;
      }
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect. Is `php artisan serve` running?',
      };
    }
  }

  // ────────────────────────────────────────────────────────────────
  //  REGISTER
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String emergencyPin,
    String? division,
    String? district,
  }) async {
    if (name.trim().isEmpty) return {'success': false, 'message': 'Please enter your name'};
    if (phone.trim().isEmpty) return {'success': false, 'message': 'Please enter your phone'};
    if (password.length < 6) return {'success': false, 'message': 'Password must be at least 6 characters'};
    if (emergencyPin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(emergencyPin)) {
      return {'success': false, 'message': 'Emergency PIN must be exactly 6 digits'};
    }

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
          'phone': phone.trim(),
          'password': password,
          'password_confirmation': password,
          'emergency_pin': emergencyPin,
          if (division != null) 'division': division,
          if (district != null) 'district': district,
        }),
      ).timeout(const Duration(seconds: 12));

      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': false, 'message': 'Server returned invalid response'};
      }

      final token = data['access_token'] as String?;
      if ((res.statusCode == 200 || res.statusCode == 201) && token != null) {
        await _saveToken(token);
        if (data['user'] != null) {
          await _saveUser(data['user']);
        } else {
          await _saveUser({'name': name.trim(), 'phone': phone.trim()});
        }
        data['token'] = token;
        data['success'] = true;
      } else {
        if (res.statusCode == 422) {
          data['message'] = _firstValidationError(data) ?? 'Invalid input';
        }
        data['success'] = false;
      }
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect. Is `php artisan serve` running?',
      };
    }
  }

  String? _firstValidationError(Map<String, dynamic> data) {
    if (data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }
    }
    return null;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveUser(dynamic user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async => (await getToken()) != null;

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
