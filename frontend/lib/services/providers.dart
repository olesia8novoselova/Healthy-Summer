// providers.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sum25_flutter_frontend/models/activity.dart';
import 'package:sum25_flutter_frontend/models/food_item.dart';
import 'package:sum25_flutter_frontend/models/meal.dart';
import 'package:sum25_flutter_frontend/services/activity/activity_api.dart';
import 'package:sum25_flutter_frontend/services/nutrition/nutrition_api.dart';
import '../models/achievement.dart';
import '../models/friend.dart';
import 'user/auth_api.dart';
import 'user/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity/step_api.dart';

class AuthProvider extends ChangeNotifier {
  final _authApi = AuthApi();
  final _userApi = UserApi();
  String? _token;
  Map<String, dynamic>? _profile;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get profile => _profile;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      _token = token;
      try {
        _profile = await _userApi.fetchProfile();
      } catch (_) {
        _token = null;
        _profile = null;
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _token = await _authApi.login(email, password);
    _profile = await _userApi.fetchProfile();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    _token = await _authApi.register(name, email, password);
    _profile = await _userApi.fetchProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authApi.logout();
    _token = null;
    _profile = null;
    notifyListeners();
  }
}

final userApiProvider = Provider((ref) => UserApi());

final friendsProvider = FutureProvider<List<Friend>>((ref) async {
  final api = ref.read(userApiProvider);
  return api.fetchFriends();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final api = ref.read(userApiProvider);
  return api.fetchAchievements();
});

final userAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final userApi = ref.read(userApiProvider);
  return userApi.fetchUserAchievements();
});

final activityApiProvider = Provider((ref) => ActivityApi());

final activitiesProvider = FutureProvider.family<List<Activity>, String?>((ref, type) {
  return ref.read(activityApiProvider).fetchActivities(type: type);
});

final stepApiProvider = Provider((ref) => StepApi());

final stepStatsProvider = FutureProvider((ref) =>
    ref.watch(stepApiProvider).fetchStepStats());

final stepHistoryProvider = FutureProvider.family((ref, int days) =>
    ref.watch(stepApiProvider).fetchStepHistory(days: days));



final foodSearchProvider = FutureProvider.family<List<FoodItem>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final resp = await http.get(
    Uri.parse('http://localhost:8080/api/nutrition/foods/search?q=$query'),
    headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);

    final foodsList = data['foods'] as List;
    return foodsList.map((e) => FoodItem.fromJson(e)).toList();
  } else {
    throw Exception('Failed to search foods (${resp.statusCode})');
  }
});



final mealsProvider = FutureProvider<List<Meal>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final resp = await http.get(
    Uri.parse('http://localhost:8080/api/nutrition/meals'),
    headers: {'Authorization': 'Bearer $token'}
  );
  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    if (data == null) return [];
    return (data as List).map((e) => Meal.fromJson(e)).toList();
  }
  throw Exception('Failed to fetch meals');
});


final nutritionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final resp = await http.get(
    Uri.parse('http://localhost:8080/api/nutrition/stats'),
    headers: {'Authorization': 'Bearer $token'}
  );
  if (resp.statusCode == 200) return jsonDecode(resp.body);
  throw Exception('Failed to fetch stats');
});

final mealApiProvider = Provider((ref) => NutritionApi());

final weeklyNutritionStatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final resp = await http.get(
    Uri.parse('http://localhost:8080/api/nutrition/stats/weekly'),
    headers: {'Authorization': 'Bearer $token'},
  );

  print('Weekly nutrition raw body: ${resp.body}');

  if (resp.statusCode == 200) {
    final body = jsonDecode(resp.body);
    if (body is List) {
      return List<Map<String, dynamic>>.from(body);
    } else {
      return []; 
    }
  }

  throw Exception('Failed to fetch weekly nutrition');
});


final todayWaterProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final resp = await http.get(
    Uri.parse('http://localhost:8080/api/nutrition/water/today'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (resp.statusCode == 200) return jsonDecode(resp.body);
  throw Exception('Failed to fetch water stats');
});

final weeklyWaterProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final resp = await http.get(
    Uri.parse('http://localhost:8080/api/nutrition/water/weekly'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (resp.statusCode == 200) {
    final decoded = jsonDecode(resp.body);
    
    if (decoded == null) return [];
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    }

    throw Exception('Expected a list but got ${decoded.runtimeType}');
  }

  throw Exception('Failed to fetch weekly water');
});

// Set water goal
final setWaterGoalProvider = FutureProvider.family<void, int>((ref, goal) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final response = await http.post(
    Uri.parse('http://localhost:8080/api/nutrition/water/goal'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'goal_ml': goal}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to set water goal');
  }
});

final waterGoalProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final response = await http.get(
    Uri.parse('http://localhost:8080/api/nutrition/water/goal'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['goal_ml'];
  } else {
    throw Exception('Failed to get water goal');
  }
});


final setCalorieGoalProvider = FutureProvider.family<void, int>((ref, goal) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final response = await http.post(
    Uri.parse('http://localhost:8080/api/nutrition/calories/goal'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'goal': goal}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to set calorie goal');
  }
});

final calorieGoalProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final response = await http.get(
    Uri.parse('http://localhost:8080/api/nutrition/calories/goal'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['goal'];
  } else {
    throw Exception('Failed to get calorie goal');
  }
});

final stepGoalProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final response = await http.get(
    Uri.parse('http://localhost:8080/api/activities/steps/goal'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['goal'];
  } else {
    throw Exception('Failed to get step goal');
  }
});

final setStepGoalProvider = FutureProvider.family<void, int>((ref, goal) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final response = await http.post(
    Uri.parse('http://localhost:8080/api/activities/steps/goal'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'goal': goal}),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to set step goal');
  }
});

final activityGoalProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final res = await http.get(
    Uri.parse('http://localhost:8080/api/activities/goal'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  if (res.statusCode != 200) throw Exception('Failed to load activity goal');
  final body = jsonDecode(res.body);
  return body['goal'] ?? 500;
});

final setActivityGoalProvider = FutureProvider.family<void, int>((ref, goal) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final res = await http.post(
    Uri.parse('http://localhost:8080/api/activities/goal'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'goal': goal}),
  );
  if (res.statusCode != 200) throw Exception('Failed to set activity goal');
});

