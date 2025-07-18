import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:sum25_flutter_frontend/config.dart';

class NutritionApi {
  final String baseUrl = '$nutritionBase';

  final http.Client _client;
  NutritionApi({http.Client? client}) : _client = client ?? http.Client();

  Future<void> addMeal({
    required int fdcId,
    required String description,
    required num calories,
    required num protein,
    required num fat,
    required num carbs,
    required double quantity,
    required String unit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await _client.post(
      Uri.parse('$baseUrl/meals'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fdcId': fdcId,
        'description': description,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'quantity': quantity,
        'unit': unit,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to add meal: ${resp.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchWeeklyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final resp = await _client.get(
      Uri.parse('$baseUrl/stats/weekly'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load weekly stats');
    }
  }


  final weeklyWaterProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final resp = await http.get(
    Uri.parse('$nutritionBase/water/weekly'),
    headers: {'Authorization': 'Bearer $token'},
  );
  debugPrint('Weekly water raw body: ${resp.body}');
  if (resp.statusCode == 200) {
    final body = jsonDecode(resp.body);
    if (body is List) {
      return List<Map<String, dynamic>>.from(body);
    } else {
      return []; 
    }
  }
  debugPrint('Weekly water raw body: ${resp.body}');

  throw Exception('Failed to fetch weekly water');
});

}
