import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StepApi {
  static const String baseUrl = 'http://localhost:8080/api/activities';

  Future<void> addSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await http.post(
      Uri.parse('$baseUrl/steps'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'steps': steps}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to add steps');
    }
  }

  Future<Map<String, dynamic>> fetchStepStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await http.get(
      Uri.parse('$baseUrl/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch step stats');
    }
  }

  Future<List<Map<String, dynamic>>> fetchStepHistory({int days = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await http.get(
      Uri.parse('$baseUrl/analytics?days=$days'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch step history');
    }
  }
}
