
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sum25_flutter_frontend/config.dart';
import 'package:sum25_flutter_frontend/models/post_activity.dart';

class WellnessApi {
  static const String baseUrl = '$wellnessBase';
  Future<List<PostActivity>> fetchFriendActivities() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception('Not authenticated');

  final resp = await http.get(
    Uri.parse('$baseUrl/activities'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (resp.statusCode != 200) {
    throw Exception('Failed to fetch activities: ${resp.body}');
  }

  final data = jsonDecode(resp.body) as List;
  return data.map((json) => PostActivity.fromJson(json)).toList();
}

Future<void> postWellnessActivity({
  required String type,
  required String message,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception('Not authenticated');

  final response = await http.post(
    Uri.parse('$baseUrl/activities'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'type': type,
      'message': message,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to post activity: ${response.body}');
  }
}
}
