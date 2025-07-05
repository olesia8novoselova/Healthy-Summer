// lib/services/auth_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://localhost:8080',
  );

  /// baseUrl ends up as 'http://…:8080/api/v1'
  final String baseUrl;
  final _client = http.Client();

  AuthApi({ String? baseUrl })
      : baseUrl = baseUrl ?? '$_host/api/v1';

  Future<bool> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/users/login');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    return res.statusCode == 200;
  }

  Future<bool> register(String name, String email, String password) async {
    final uri = Uri.parse('$baseUrl/users/register');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      return true;
    }

    // Try to parse {"error":"..."} from the body
    String message;
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      message = body['error'] ?? 'Registration failed (${res.statusCode})';
    } catch (_) {
      message = 'Registration failed (${res.statusCode})';
    }

    // Throw so UI can catch it
    throw Exception(message);
  }
}
