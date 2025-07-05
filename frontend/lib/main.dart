import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/profile_screen.dart';

import 'screens/auth_screen.dart';
import 'screens/register_screen.dart';


void main() {
  runApp(const ProviderScope(child: CourseApp()));
}

class CourseApp extends StatelessWidget {
  const CourseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Activity Tracker Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.white,
          secondary: const Color(0xFFF8BBD0), // Soft pink
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/profile', builder: (ctx, st) => const ProfileScreen()),
  ],
);
