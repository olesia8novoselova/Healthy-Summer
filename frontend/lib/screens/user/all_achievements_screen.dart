import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';

class AllAchievementsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(achievementsProvider);
    final userAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('All Achievements', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.pink),
      ),
      body: allAsync.when(
        data: (allAchievements) => userAsync.when(
          data: (userAchievements) {
            final unlockedIds = userAchievements.map((a) => a.id).toSet();
            return ListView(
              padding: EdgeInsets.all(16),
              children: allAchievements.map((a) {
                final unlocked = unlockedIds.contains(a.id);
                return ListTile(
                  leading: Icon(
                    unlocked ? Icons.emoji_events : Icons.lock_outline,
                    color: unlocked ? Colors.pink : Colors.grey,
                  ),
                  title: Text(
                    a.title,
                    style: TextStyle(
                      color: unlocked ? Colors.pink : Colors.grey,
                      fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load user achievements', style: TextStyle(color: Colors.red))),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load achievements', style: TextStyle(color: Colors.red))),
      ),
    );
  }
}

