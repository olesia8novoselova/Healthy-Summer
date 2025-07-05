import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_api.dart';
import '../models/user_profile.dart';
import '../models/friend.dart';
import '../models/achievement.dart';
import 'auth_api.dart';

final userApiProvider = Provider((_) => UserApi());

final authApiProvider = Provider((_) => AuthApi());

// 1. Profile
final profileProvider = FutureProvider<UserProfile>((ref) {
  return ref.read(userApiProvider).getProfile();
});

// 2. Friends
final friendsProvider = FutureProvider<List<Friend>>((ref) {
  return ref.read(userApiProvider).getFriends();
});

// 3. Achievements
final achievementsProvider = FutureProvider<List<Achievement>>((ref) {
  return ref.read(userApiProvider).getAchievements();
});
