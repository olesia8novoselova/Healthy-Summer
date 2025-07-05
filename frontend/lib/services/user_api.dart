// lib/services/user_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/friend.dart';
import '../models/achievement.dart';

class UserApi {
  static const _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://localhost:8080',
  );

  /// Base URL ends up as 'http://localhost:8080/api/v1'
  final String baseUrl;
  final _client = http.Client();

  UserApi({ String? baseUrl })
      : baseUrl = baseUrl ?? '$_host/api/v1';

  Future<UserProfile> getProfile() async {
    final uri = Uri.parse('$baseUrl/users/profile');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load profile');
    }
    return UserProfile.fromJson(json.decode(res.body));
  }

  Future<void> updateProfile(UserProfile profile) async {
    final uri = Uri.parse('$baseUrl/users/profile');
    final res = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(profile.toJson()),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  Future<void> requestFriend(String email) async {
    final uri = Uri.parse('$baseUrl/users/friends/request');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to send friend request');
    }
  }

  Future<List<Friend>> getFriends() async {
    final uri = Uri.parse('$baseUrl/users/friends');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load friends');
    }
    final list = json.decode(res.body) as List;
    return list.map((e) => Friend.fromJson(e)).toList();
  }

  Future<List<Achievement>> getAchievements() async {
    final uri = Uri.parse('$baseUrl/users/achievements');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load achievements');
    }
    final list = json.decode(res.body) as List;
    return list.map((e) => Achievement.fromJson(e)).toList();
  }
}
