// user_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserApi {
  static const String baseUrl = 'http://localhost:8080/api/v1/users';

  Future<Map<String, dynamic>> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_errorFromResponse(response));
    }
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
}
