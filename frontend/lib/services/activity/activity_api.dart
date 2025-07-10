import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sum25_flutter_frontend/models/activity.dart';

class ActivityApi {
  final String baseUrl = 'http://localhost:8080/api/activities';

  Future<void> addActivity({
    required String type,
    required String name,
    required int duration,
    required String intensity,
    required int calories,
    required String location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await http.post(
      Uri.parse('$baseUrl'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'name': name,
        'duration': duration,
        'intensity': intensity,
        'calories': calories,
        'location': location,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to add activity');
    }
  }

  Future<List<Activity>> fetchActivities({String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = type == null
        ? '$baseUrl'
        : '$baseUrl?type=$type';
    final resp = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded == null) return [];
      if (decoded is List) {
        return decoded.map((e) => Activity.fromJson(e)).toList();
      } else {
        return [];
      }  
    } else {
      throw Exception('Failed to fetch activities');
    }
  }
}
