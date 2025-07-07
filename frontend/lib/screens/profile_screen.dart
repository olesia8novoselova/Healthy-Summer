import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart'; // adjust if needed
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.pink),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.pink),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              context.go('/');
            },
          )
        ],
      ),
      body: authAsync.when(
        data: (authState) => authState.profile == null
            ? Center(child: Text('No profile loaded', style: TextStyle(color: Colors.pink)))
            : Center(child: Text('Welcome, ${authState.profile!['name']}', style: TextStyle(fontSize: 20, color: Colors.pink))),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.red))),
      ),
    );
  }
}
