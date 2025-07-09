// providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum25_flutter_frontend/models/activity.dart';
import 'package:sum25_flutter_frontend/services/activity_api.dart';
import '../models/achievement.dart';
import '../models/friend.dart';
import 'auth_api.dart';
import 'user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

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


