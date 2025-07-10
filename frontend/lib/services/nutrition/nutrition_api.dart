import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NutritionApi {
  final String baseUrl = 'http://localhost:8080/api/nutrition';

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
    final resp = await http.post(
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
}
