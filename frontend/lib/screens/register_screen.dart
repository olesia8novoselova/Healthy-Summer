import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart'; // adjust import if needed
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);

    // If already authenticated, go to profile
    authAsync.whenOrNull(
      data: (authState) {
        if (authState.token != null) {
          Future.microtask(() => context.go('/profile'));
        }
      },
    );

    final isLoading = authAsync.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Register', style: TextStyle(fontSize: 24, color: Colors.pink)),
                SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.pink),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.pink),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.pink),
                  ),
                  obscureText: true,
                ),
                if (_error != null) ...[
                  SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Colors.red)),
                ],
                SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                        onPressed: () async {
                          setState(() {
                            _error = null;
                          });
                          await ref.read(authProvider.notifier).register(
                                _nameController.text,
                                _emailController.text,
                                _passwordController.text,
                              );
                          final state = ref.read(authProvider);
                          if (state.hasError) {
                            setState(() {
                              _error = state.error?.toString();
                            });
                          }
                        },
                        child: Text('Register', style: TextStyle(color: Colors.white)),
                      ),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text('Back to Login', style: TextStyle(color: Colors.pink)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
