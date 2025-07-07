// auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_api.dart';
import 'user_api.dart';

class AuthState {
  final String? token;
  final Map<String, dynamic>? profile;
  AuthState({this.token, this.profile});

  AuthState copyWith({String? token, Map<String, dynamic>? profile}) {
    return AuthState(
      token: token ?? this.token,
      profile: profile ?? this.profile,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  final _authApi = AuthApi();
  final _userApi = UserApi();

  @override
  Future<AuthState> build() async {
    // try load token/profile on startup
    final token = await _authApi.getStoredToken();
    if (token == null) return AuthState();
    try {
      final profile = await _userApi.fetchProfile();
      return AuthState(token: token, profile: profile);
    } catch (_) {
      return AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final token = await _authApi.login(email, password);
      final profile = await _userApi.fetchProfile();
      state = AsyncData(AuthState(token: token, profile: profile));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      final token = await _authApi.register(name, email, password);
      final profile = await _userApi.fetchProfile();
      state = AsyncData(AuthState(token: token, profile: profile));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    await _authApi.logout();
    state = AsyncData(AuthState());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
