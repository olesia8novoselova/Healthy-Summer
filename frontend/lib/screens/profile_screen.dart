import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/friend.dart';
import '../models/achievement.dart';
import '../services/user_api.dart';
import '../services/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pink = const Color(0xFFF8BBD0);

    final profileAsync = ref.watch(profileProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final achAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), backgroundColor: pink),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Info ───────────────────────────────────────
            profileAsync.when(
              data: (UserProfile p) => _buildProfileSection(context, ref, p, pink),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading profile: $e'),
            ),
            const SizedBox(height: 24),

            // ── Friends ─────────────────────────────────────────────
            Text('Friends', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            friendsAsync.when(
              data: (List<Friend> list) => _buildFriendsSection(context, ref, list, pink),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            // ── Achievements ───────────────────────────────────────
            Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            achAsync.when(
              data: (List<Achievement> list) =>
                  _buildAchievementsSection(list, pink),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, WidgetRef ref, UserProfile p, Color pink) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage:
              p.avatarUrl.isNotEmpty ? NetworkImage(p.avatarUrl) : null,
          child: p.avatarUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontSize: 20)),
            Text(p.email, style: const TextStyle(color: Colors.grey)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditProfileDialog(context, ref, p, pink),
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref,
      UserProfile profile, Color pink) {
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: pink),
            onPressed: () async {
              final updated = UserProfile(
                id: profile.id,
                name: nameCtrl.text,
                email: emailCtrl.text,
                avatarUrl: profile.avatarUrl,
              );
              await ref.read(userApiProvider).updateProfile(updated);
              ref.refresh(profileProvider);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection(BuildContext context, WidgetRef ref,
      List<Friend> list, Color pink) {
    return Column(
      children: [
        for (var f in list)
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(f.name),
            subtitle: Text(f.email),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friend'),
            style: ElevatedButton.styleFrom(backgroundColor: pink),
            onPressed: () => _showAddFriendDialog(context, ref, pink),
          ),
        ),
      ],
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref, Color pink) {
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request Friend'),
        content: TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(labelText: 'Friend\'s Email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: pink),
            onPressed: () async {
              await ref.read(userApiProvider).requestFriend(emailCtrl.text);
              ref.refresh(friendsProvider);
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(List<Achievement> list, Color pink) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: list.map((a) {
        return Column(
          children: [
            Opacity(
              opacity: a.unlocked ? 1 : 0.3,
              child: Image.network(a.iconUrl, height: 48, width: 48),
            ),
            const SizedBox(height: 4),
            Text(a.title, textAlign: TextAlign.center),
          ],
        );
      }).toList(),
    );
  }
}
