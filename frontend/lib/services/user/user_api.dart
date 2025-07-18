// user_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sum25_flutter_frontend/config.dart';
import 'package:sum25_flutter_frontend/models/friend_request.dart';
import '../../models/friend.dart';
import '../../models/achievement.dart';

class UserApi {
  static const String baseUrl = '$usersBase';

  final http.Client _client;
  UserApi({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  Future<Map<String, dynamic>> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('Not authenticated');
    final response = await _client.get(
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

    Future<List<Friend>> fetchFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await _client.get(
      Uri.parse('$baseUrl/friends'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      return data.map((e) => Friend.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load friends');
    }
  }

  Future<List<Achievement>> fetchAchievements() async {
    print('Fetching achievements...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await _client.get(
      Uri.parse('$baseUrl/achievements'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('Achievements response: ${resp.body}');
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      return data.map((e) => Achievement.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load achievements');
    }
  }

  Future<List<Achievement>> fetchUserAchievements() async {
  print('Fetching user achievements...');
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final resp = await _client.get(
    Uri.parse('$baseUrl/users/achievements'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  print('User achievements response: ${resp.body}');
  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body) as List;
    return data.map((e) => Achievement.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load user achievements');
  }
}

  Future<void> sendFriendRequest(String friendEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await _client.post(
      Uri.parse('$baseUrl/friends/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': friendEmail}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send friend request: ${response.body}');
    }
  }

  Future<void> updateProfile(String name, String avatarUrl, double? weight, double? height) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await _client.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'avatarUrl': avatarUrl,
        'weight': weight,
        'height': height,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  Future<List<FriendRequest>> fetchFriendRequests() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception('Not authenticated');
  
  final resp = await _client.get(
    Uri.parse('$baseUrl/friends/requests'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (resp.statusCode == 200) {
    final list = jsonDecode(resp.body) as List;
    return list
      .cast<Map<String, dynamic>>()
      .map((json) => FriendRequest.fromJson(json))
      .toList();
  } else {
    throw Exception('Failed to load friend requests: ${resp.body}');
  }
}


  Future<void> acceptFriendRequest(String requestId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception('Not authenticated');
  final resp = await _client.post(
    Uri.parse('$baseUrl/friends/requests/$requestId/accept'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  print('FriendAcceptRequests HTTP status: ${resp.statusCode}');
  print('FriendAcceptRequests HTTP body: ${resp.body}');

  if (resp.statusCode != 200) {
    throw Exception('Failed to accept friend request: ${resp.body}');
  }
}

Future<void> declineFriendRequest(String requestId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception('Not authenticated');
  final resp = await _client.post(
    Uri.parse('$baseUrl/friends/requests/$requestId/decline'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (resp.statusCode != 200) {
    throw Exception('Failed to decline friend request: ${resp.body}');
  }
}
}
