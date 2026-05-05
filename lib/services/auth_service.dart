import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey  = 'auth_user';

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      // Backend returns 'access_token'
      final token = data['access_token'] as String?;
      if ((res.statusCode == 200 || res.statusCode == 201) && token != null) {
        await _saveToken(token);
        if (data['user'] != null) await _saveUser(data['user']);
      }
      // Normalize: always expose as 'token' for Flutter
      if (token != null) data['token'] = token;
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Connection failed. Is the server running?'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    String emergencyPin = '000000',
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
          'password_confirmation': password,
          'emergency_pin': emergencyPin,  // 6 digits as backend requires
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if ((res.statusCode == 200 || res.statusCode == 201) && token != null) {
        await _saveToken(token);
        // Backend doesn't return user object on register, save phone/name manually
        await _saveUser({'name': name, 'phone': phone});
      }
      if (token != null) data['token'] = token;
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Connection failed. Is the server running?'};
    }
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
    return raw != null ? jsonDecode(raw) : null;
  }

  Future<bool> isLoggedIn() async => (await getToken()) != null;

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
