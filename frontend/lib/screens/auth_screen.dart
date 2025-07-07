import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart'; // use your correct import path
import 'package:go_router/go_router.dart';

class AuthScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);

    authAsync.whenOrNull(
      data: (authState) {
        if (authState.token != null) {
          Future.microtask(() => context.go('/profile'));
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Login', style: TextStyle(fontSize: 24, color: Colors.pink)),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.pink)),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.pink)),
                obscureText: true,
              ),
              if (_error != null) ...[
                SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Colors.red)),
              ],
              SizedBox(height: 20),
              authAsync.isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                      onPressed: () async {
                        setState(() => _error = null);
                        await ref.read(authProvider.notifier).login(
                              _emailController.text,
                              _passwordController.text,
                            );
                        final err = ref.read(authProvider).error;
                        if (err != null) setState(() => _error = err.toString());
                      },
                      child: Text('Login', style: TextStyle(color: Colors.white)),
                    ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text('Register', style: TextStyle(color: Colors.pink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
