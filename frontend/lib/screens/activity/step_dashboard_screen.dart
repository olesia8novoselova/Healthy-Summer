import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum25_flutter_frontend/screens/activity/step_goals_screen.dart';
import '../../services/providers.dart';


class StepDashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(stepStatsProvider);
    final goalReached = ref.watch(stepGoalReachedProvider);
    final alreadyNotified = ref.watch(stepGoalNotifiedProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (goalReached && !alreadyNotified) {
        ref.read(stepGoalNotifiedProvider.notifier).state = true;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("🎉 Step Goal Reached!"),
            content: Text("You've reached your step goal today! Want to share it with friends?"),
            actions: [
              TextButton(
                child: Text("Not now"),
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.pink),
              ),
              TextButton(
                child: Text("Share"),
                onPressed: () async {
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  await Future.delayed(const Duration(milliseconds: 200)); 
                  try {
                    await ref.read(wellnessApiProvider).postWellnessActivity(
                      type: "steps_goal",
                      message: "I just hit my step goal for today! 🚶‍♂️🎯",
                    );
                    ref.invalidate(friendActivitiesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Shared with friends! 🎉")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to share: $e")),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.pink),
              )
            ],
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Steps', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.pink),
            onPressed: () => context.push('/steps/history'),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: statsAsync.when(
              data: (stats) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Today', style: TextStyle(fontSize: 18, color: Colors.pink)),
                    SizedBox(height: 12),
                    ref.watch(stepGoalProvider).when(
                      data: (goal) => Column(
                        children: [
                          Text('${stats['today'] ?? 0} / $goal steps', style: TextStyle(fontSize: 28, color: Colors.pink)),
                          SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: ((stats['today'] ?? 0) / goal).clamp(0, 1),
                            backgroundColor: Colors.pink[50],
                            color: Colors.pink,
                            minHeight: 16,
                          ),
                        ],
                      ),
                      loading: () => CircularProgressIndicator(),
                      error: (e, _) => Text('Error loading goal: $e'),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Weekly: ${stats['weekly_total'] ?? 0}', style: TextStyle(color: Colors.pink)),
                        Text('Monthly: ${stats['monthly_total'] ?? 0}', style: TextStyle(color: Colors.pink)),
                      ],
                    ),
                    SizedBox(height: 40),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.directions_walk),
                      label: Text('+1000 Steps'),
                      onPressed: () async {
                        try {
                          await ref.read(stepApiProvider).addSteps((stats['today'] ?? 0) + 1000);
                          ref.invalidate(stepStatsProvider);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e', style: TextStyle(color: Colors.red))),
            ),
          ),
          ListTile(
            leading: Icon(Icons.flag, color: Colors.pink),
            title: Text("Set Step Goal", style: TextStyle(color: Colors.black)),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StepGoalSettingsScreen()),
              ).then((_) {
                ref.invalidate(stepGoalProvider);
              });
            },
          ),
        ],
      ),
    );
  }
}
