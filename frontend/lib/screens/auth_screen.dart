// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pink = const Color(0xFFF8BBD0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: pink.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sign In', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: pink)),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: pink),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: pink),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: pink),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: pink),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final api = ref.read(authApiProvider);
                      final ok = await api.login(_emailCtrl.text, _passCtrl.text);
                      if (ok) {
                        context.go('/profile');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login failed')),
                        );
                      }
                    },
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.go('/register'),
                  child: Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: pink, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
