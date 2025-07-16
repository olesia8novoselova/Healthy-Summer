// providers.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sum25_flutter_frontend/models/activity.dart';
import 'package:sum25_flutter_frontend/models/challenge.dart';
import 'package:sum25_flutter_frontend/models/food_item.dart';
import 'package:sum25_flutter_frontend/models/friend_request.dart';
import 'package:sum25_flutter_frontend/models/meal.dart';
import 'package:sum25_flutter_frontend/models/message.dart';
import 'package:sum25_flutter_frontend/models/post_activity.dart';
import 'package:sum25_flutter_frontend/services/activity/activity_api.dart';
import 'package:sum25_flutter_frontend/services/nutrition/nutrition_api.dart';
import 'package:sum25_flutter_frontend/services/wellness/challenge_api.dart';
import 'package:sum25_flutter_frontend/services/wellness/chat_api.dart';
import 'package:sum25_flutter_frontend/services/wellness/wellness_api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/achievement.dart';
import '../models/friend.dart';
import 'user/auth_api.dart';
import 'user/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity/step_api.dart';
import 'package:collection/collection.dart';

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
  return ref.read(userApiProvider).fetchFriends();
});

final friendRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  return ref.read(userApiProvider).fetchFriendRequests();
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

final todayActivityCaloriesProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final res = await http.get(
    Uri.parse('http://localhost:8080/api/activities/today-calories'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  if (res.statusCode != 200) throw Exception('Failed to fetch today\'s calories');
  final body = jsonDecode(res.body);
  return body['calories'] ?? 0;
});

final weeklyActivityStatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  
  final res = await http.get(
    Uri.parse('http://localhost:8080/api/activities/activity/weekly'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) throw Exception('Failed to fetch weekly stats');

  final decoded = jsonDecode(res.body);
  if (decoded is List) {
    return List<Map<String, dynamic>>.from(decoded);
  }
  if (decoded is Map && decoded['days'] is List) {
    return List<Map<String, dynamic>>.from(decoded['days']);
  }
  throw Exception('Unexpected payload for weekly activity stats: ${decoded.runtimeType}');
});

final wellnessApiProvider = Provider((ref) => WellnessApi());

final friendActivitiesProvider = FutureProvider<List<PostActivity>>((ref) async {
  return ref.read(wellnessApiProvider).fetchFriendActivities();
});

final goalNotifiedProvider = StateProvider<bool>((ref) => false);

final activityGoalReachedProvider = Provider<bool>((ref) {
  final goal = ref.watch(activityGoalProvider).asData?.value ?? 0;
  final calories = ref.watch(todayActivityCaloriesProvider).asData?.value ?? 0;
  return calories >= goal && goal > 0;
});

final stepGoalReachedProvider = Provider<bool>((ref) {
  final goal = ref.watch(stepGoalProvider).asData?.value ?? 0;
  final stats = ref.watch(stepStatsProvider).asData?.value;
  final steps = stats?['today'] ?? 0;
  return steps >= goal && goal > 0;
});

final postWellnessStatusProvider = FutureProvider.family<void, String>((ref, message) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final res = await http.post(
    Uri.parse('http://localhost:8080/api/wellness/activities'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'type': 'status',
      'message': message,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to post status: ${res.body}');
  }

});

final stepGoalNotifiedProvider = StateProvider<bool>((ref) => false);

final cachedAchievementIdsProvider = StateProvider<List<String>>((ref) => []);

final loadCachedAchievementsProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final ids = prefs.getStringList('shared_achievements') ?? [];
  ref.read(cachedAchievementIdsProvider.notifier).state = ids;
});

final unsharedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final achievementsAsync = ref.watch(userAchievementsProvider);
  final cached = ref.watch(cachedAchievementIdsProvider);

  return achievementsAsync.when(
    data: (achievements) => achievements
        .where((a) => a.unlocked && !cached.contains(a.id))
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final markAchievementSharedProvider = Provider.family<Future<void>, String>((ref, achievementId) async {
  final prefs = await SharedPreferences.getInstance();
  final current = List<String>.from(ref.read(cachedAchievementIdsProvider));
  if (!current.contains(achievementId)) {
    current.add(achievementId);
    await prefs.setStringList('shared_achievements', current);
    ref.read(cachedAchievementIdsProvider.notifier).state = current;
  }
});

const _chatBaseUrl = 'http://localhost:8080/api/wellness';

final chatApiProvider = Provider((ref) => ChatApi(baseUrl: _chatBaseUrl));

final chatListProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception('Not authenticated');

  final res = await http.get(
    Uri.parse('$_chatBaseUrl/friends'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to fetch chat list: ${res.body}');
  }

  final data = jsonDecode(res.body) as List;

  return data.map((e) => Map<String, String>.from(e)).toList();
});

final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, friendName) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception('Not authenticated');

  final res = await http.get(
    Uri.parse('$_chatBaseUrl/messages/$friendName'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to fetch messages: ${res.body}');
  }

  final data = jsonDecode(res.body) as List;
  return data
      .map((json) => Message.fromJson(json as Map<String, dynamic>))
      .toList();
});

final postMessageProvider =
    FutureProvider.family<void, Message>((ref, message) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null) throw Exception('Not authenticated');

  final res = await http.post(
    Uri.parse('$_chatBaseUrl/messages'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(message.toJson()),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to send message: ${res.body}');
  }
});

class ChatController extends StateNotifier<WebSocketChannel?> {
  final ChatApi api;
  final String userId;

  ChatController({required this.api, required this.userId}) : super(null) {
    _connect();
  }

  Stream<dynamic>? _broadcast;
  Stream<dynamic> get wsStream => _broadcast ?? const Stream.empty();

  Future<void> _connect() async {
    final ch = await api.connectSocket(userId);
    state = ch;
    _broadcast = ch.stream.asBroadcastStream();
  }

  void send(Map<String, dynamic> msg) => state?.sink.add(jsonEncode(msg));

  @override
  void dispose() {
    state?.sink.close();
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider
    .family<ChatController, WebSocketChannel?, String>((ref, userId) {
  final api = ref.watch(chatApiProvider);
  return ChatController(api: api, userId: userId);
});

final userIdProvider = FutureProvider<String>((ref) async {
  final prefs  = await SharedPreferences.getInstance();
  final token  = prefs.getString('jwt_token') ?? '';
  if (token.isEmpty) return '';

  final parts = token.split('.');
  if (parts.length != 3) return '';

  final payload = parts[1]
      .replaceAll('-', '+')
      .replaceAll('_', '/')
      .padRight(parts[1].length + (4 - parts[1].length % 4) % 4, '=');

  try {
    final decoded = utf8.decode(base64.decode(payload));
    final json    = jsonDecode(decoded);
    return json['userId'] as String? ?? '';
  } catch (_) {
    return '';
  }
});

class _ChatSession {
  final messages = <Message>[];
  final seenIds  = <String>{};
  bool historyLoaded = false;
}

final chatSessionProvider =
    StateNotifierProvider.family<_ChatSessionNotifier, _ChatSession, String>((ref, friendId) {
  return _ChatSessionNotifier();
});

class _ChatSessionNotifier extends StateNotifier<_ChatSession> {
  _ChatSessionNotifier() : super(_ChatSession());


  void add(Message m) {
    if (state.seenIds.add(m.id)) state.messages.add(m);
  }

  void addMany(Iterable<Message> list) {
    for (final m in list) add(m);
  }

  void markHistoryLoaded() => state.historyLoaded = true;
}

final challengeApiProvider = Provider((_)=>ChallengeApi());

final challengesProvider = FutureProvider<List<Challenge>>((ref) {
  return ref.read(challengeApiProvider).list();
});
final leaderboardProvider  = FutureProvider.family<List<Participant>,String>((ref,id)=>ref.read(challengeApiProvider).leaderboard(id));
final createChallengeProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) {
  return ref.read(challengeApiProvider).create(
    params['title']       as String,
    params['type']        as String,
    params['target']      as int,
    participants: (params['participants'] as List).cast<String>(),
  );
});

// returns true when *you* reached the target of this challenge
final challengeCompletedProvider =
    FutureProvider.family<bool, Challenge>((ref, ch) async {
  final lbs = await ref.watch(leaderboardProvider(ch.id).future);
  final uid = ref.read(userIdProvider).valueOrNull;
  final me  = lbs.firstWhereOrNull((p) => p.userId == uid);
  return me != null && me.progress >= ch.target;
});

/// Keeps ids we’ve already popped a dialog for in this session.
final challengeNotifiedProvider =
    StateProvider<Set<String>>((_) => <String>{});
