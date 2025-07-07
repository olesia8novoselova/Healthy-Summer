import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';
import '../services/providers.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final userAchievementsAsync = ref.watch(userAchievementsProvider);


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
        data: (authState) {
          if (authState.profile == null) {
            return Center(child: Text('No profile loaded', style: TextStyle(color: Colors.pink)));
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${authState.profile!['name']}', style: TextStyle(fontSize: 20, color: Colors.pink)),
                SizedBox(height: 24),
                // Friends
                Text('Friends', style: TextStyle(fontSize: 18, color: Colors.pink, fontWeight: FontWeight.bold)),
                friendsAsync.when(
                  data: (friends) => friends.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No friends yet', style: TextStyle(color: Colors.pink)),
                            TextButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (ctx) => AddFriendDialog(ref: ref),
                              ),
                              child: Text('Add Friend', style: TextStyle(color: Colors.pink)),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ...friends.map((f) => ListTile(
                              title: Text(f.name, style: TextStyle(color: Colors.pink)),
                              subtitle: Text(f.email, style: TextStyle(color: Colors.black54)),
                              leading: Icon(Icons.person, color: Colors.pink),
                            )),
                            TextButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (ctx) => AddFriendDialog(ref: ref),
                              ),
                              child: Text('Add Friend', style: TextStyle(color: Colors.pink)),
                            ),
                          ],
                        ),
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No friends yet', style: TextStyle(color: Colors.pink)),
                      TextButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => AddFriendDialog(ref: ref),
                        ),
                        child: Text('Add Friend', style: TextStyle(color: Colors.pink)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Achievements: always show "Add Achievement" button, even if GET endpoint doesn't work
                Text('Achievements', style: TextStyle(fontSize: 18, color: Colors.pink, fontWeight: FontWeight.bold)),
                userAchievementsAsync.when(
                  data: (achievements) {
                    final unlocked = achievements.where((a) => a.unlocked).toList();
                    return unlocked.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No achievements yet', style: TextStyle(color: Colors.pink)),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (ctx) => AddAchievementDialog(ref: ref),
                                    ),
                                    child: Text('Add Achievement', style: TextStyle(color: Colors.pink)),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/all_achievements'),
                                    child: Text('See All Achievements', style: TextStyle(color: Colors.pink)),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...unlocked.map((a) => ListTile(
                                title: Text(a.title, style: TextStyle(color: Colors.pink)),
                                leading: Icon(Icons.emoji_events, color: Colors.pink),
                              )),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (ctx) => AddAchievementDialog(ref: ref),
                                    ),
                                    child: Text('Add Achievement', style: TextStyle(color: Colors.pink)),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/all_achievements'),
                                    child: Text('See All Achievements', style: TextStyle(color: Colors.pink)),
                                  ),
                                ],
                              ),
                            ],
                          );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Failed to load achievements', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.red))),
      ),
    );
  }
}

class AddFriendDialog extends StatefulWidget {
  final WidgetRef ref;
  const AddFriendDialog({required this.ref, super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final _emailController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Friend', style: TextStyle(color: Colors.pink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Friend Email',
              labelStyle: TextStyle(color: Colors.pink),
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () async {
            setState(() {
              _loading = true;
              _error = null;
            });
            try {
              // Implement userApi request here
              await widget.ref.read(userApiProvider).sendFriendRequest(_emailController.text);
              Navigator.pop(context);
              widget.ref.refresh(friendsProvider);
            } catch (e) {
              setState(() {
                _error = e.toString().replaceFirst('Exception:', '').trim();
              });
            } finally {
              setState(() { _loading = false; });
            }
          },
          child: _loading
              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Send', style: TextStyle(color: Colors.pink)),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.pink)),
        ),
      ],
    );
  }
}

class AddAchievementDialog extends StatefulWidget {
  final WidgetRef ref;
  const AddAchievementDialog({required this.ref, super.key});

  @override
  State<AddAchievementDialog> createState() => _AddAchievementDialogState();
}

class _AddAchievementDialogState extends State<AddAchievementDialog> {
  final _titleController = TextEditingController();
  final _iconUrlController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Achievement', style: TextStyle(color: Colors.pink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: Colors.pink),
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
      
      actions: [
        TextButton(
          onPressed: _loading ? null : () async {
            setState(() {
              _loading = true;
              _error = null;
            });
            try {
              // You must implement a userApi.createAchievement(title, iconUrl)
              await widget.ref.read(userApiProvider).createAchievement(
                widget.ref,
                _titleController.text,
                _iconUrlController.text,
              );
              Navigator.pop(context);
              // widget.ref.refresh(achievementsProvider); // if/when you have a GET endpoint
            } catch (e) {
              setState(() {
                _error = e.toString().replaceFirst('Exception:', '').trim();
              });
            } finally {
              setState(() { _loading = false; });
            }
          },
          child: _loading
              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Add', style: TextStyle(color: Colors.pink)),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.pink)),
        ),
      ],
    );
  }
}
