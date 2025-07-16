import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final String id;
  ChallengeDetailScreen(this.id, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final int target = ref.watch(challengesProvider).maybeWhen(
      data: (list) => list.firstWhereOrNull((c) => c.id == id)?.target ?? 1,
      orElse: () => 1,
    );

    final lbAsync = ref.watch(leaderboardProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard',
            style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
      ),
      body: lbAsync.when(
        data: (rows) => ListView(
          padding: const EdgeInsets.all(16),
          children: rows.asMap().entries.map((e) {
            final idx = e.key;
            final p   = e.value;
            final pct = (p.progress / target).clamp(0.0, 1.0);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.pink[100],
                child: Text('#${idx + 1}'),
              ),
              title: LinearProgressIndicator(
                value: pct,
                color: Colors.pink,
                backgroundColor: Colors.pink[50],
              ),
              subtitle: Text('${p.progress} / $target'),
            );
          }).toList(),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
