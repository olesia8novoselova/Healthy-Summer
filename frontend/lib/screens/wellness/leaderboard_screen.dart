import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum25_flutter_frontend/models/challenge.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    ref.listen<AsyncValue<List<Challenge>>>(
      challengesProvider,
      (_, next) {
        next.whenData((list) async {
          final uid = ref.read(userIdProvider).valueOrNull;
          if (uid == null) return;

          final notified = ref.read(challengeNotifiedProvider);

          for (final ch in list) {
            final done =
                await ref.read(challengeCompletedProvider(ch).future);
            if (done && !notified.contains(ch.id)) {
              ref
                  .read(challengeNotifiedProvider.notifier)
                  .update((s) => {...s, ch.id});
              _showCompletionDialog(ctx, ref, ch);
            }
          }
        });
      },
    );

    final chAsync = ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
        onPressed: () => showDialog(
          context: ctx,
          builder: (_) => CreateChallengeDialog(ref: ref),
        ),
      ),
      body: chAsync.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No challenges'))
            : ListView(
                children: list
                    .map(
                      (c) => ListTile(
                        title:
                            Text(c.title, style: const TextStyle(color: Colors.pink)),
                        subtitle: Text('${c.type} • target ${c.target}'),
                        onTap: () => ctx.push('/challenge/${c.id}'),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showCompletionDialog(
      BuildContext ctx, WidgetRef ref, Challenge ch) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Challenge Completed!'),
        content: Text(
            'You finished “${ch.title}”. Share the triumph with friends?'),
        actions: [
          TextButton(
            child: const Text('Not now'),
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.pink),
          ),
          TextButton(
            child: const Text('Share'),
            onPressed: () async {
              if (ctx.mounted && Navigator.canPop(ctx)) Navigator.pop(ctx);
              await Future.delayed(const Duration(milliseconds: 200));
              try {
                await ref.read(wellnessApiProvider).postWellnessActivity(
                  type: 'challenge_completed',
                  message:
                      'I just completed the “${ch.title}” challenge! 🏅',
                );
                ref.invalidate(friendActivitiesProvider);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Shared! 🎉')),
                );
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.pink),
          ),
        ],
      ),
    );
  }
}

class CreateChallengeDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const CreateChallengeDialog({required this.ref});

  @override
  ConsumerState<CreateChallengeDialog> createState() =>
      _CreateChallengeDialogState();
}

class _CreateChallengeDialogState
    extends ConsumerState<CreateChallengeDialog> {
  final _title = TextEditingController();
  final _target = TextEditingController();
  String _type = 'steps';

  // invites
  final _emailController = TextEditingController();
  final List<String> _invites = [];

  bool _loading = false;
  String? _err;

  @override
  Widget build(BuildContext ctx) {
    return AlertDialog(
      title: const Text('New Group Challenge',
          style: TextStyle(color: Colors.pink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          DropdownButton<String>(
            value: _type,
            items: [
              ['steps', 'Step Count'],
              ['workouts', 'Workout per day'],
              ['calories', 'Calories per day']
            ]
                .map((p) => DropdownMenuItem(value: p[0], child: Text(p[1])))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          TextField(
            controller: _target,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _type == 'steps' ? 'Steps' : 'Target',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Friend email'),
            onSubmitted: (v) {
              if (v.isNotEmpty) {
                setState(() {
                  _invites.add(v.trim());
                  _emailController.clear();
                });
              }
            },
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _invites
                .map(
                  (e) => Chip(
                    label: Text(e),
                    onDeleted: () =>
                        setState(() => _invites.remove(e)),
                  ),
                )
                .toList(),
          ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_err!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: Colors.pink)),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() {
                    _loading = true;
                    _err = null;
                  });

                  final pending = _emailController.text.trim();
                  if (pending.isNotEmpty && !_invites.contains(pending)) {
                    _invites.add(pending);
                  }

                  try {
                    final t = int.parse(_target.text);
                    await widget.ref.read(createChallengeProvider({
                      'title': _title.text,
                      'type': _type,
                      'target': t,
                      'participants': List<String>.from(_invites),
                    }).future);
                    widget.ref.invalidate(challengesProvider);
                    Navigator.pop(ctx);
                  } catch (e) {
                    setState(() => _err = '$e');
                  } finally {
                    setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator())
              : const Text('Create', style: TextStyle(color: Colors.pink)),
        ),
      ],
    );
  }
}
