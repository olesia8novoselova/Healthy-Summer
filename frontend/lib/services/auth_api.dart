// auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  static const String baseUrl = 'http://localhost:8080/api/users';

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      return token;
    } else {
      throw Exception(_errorFromResponse(response));
    }
  }

  Future<String> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      return token;
    } else {
      throw Exception(_errorFromResponse(response));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static String _errorFromResponse(http.Response resp) {
    try {
      final data = jsonDecode(resp.body);
      if (data is Map && data.containsKey('error')) {
        return data['error'].toString();
      }
    } catch (_) {}
    return 'Unknown error: ${resp.body}';
  }

  Future<String?> getStoredToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('jwt_token');
}

}

