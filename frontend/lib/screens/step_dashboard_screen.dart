import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/providers.dart';

class StepDashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(stepStatsProvider);

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
      body: statsAsync.when(
        data: (stats) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Today', style: TextStyle(fontSize: 18, color: Colors.pink)),
              SizedBox(height: 12),
              Text('${stats['today'] ?? 0} / ${stats['goal'] ?? 10000} steps',
                  style: TextStyle(fontSize: 28, color: Colors.pink)),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: (stats['progress'] ?? 0.0).toDouble().clamp(0, 1),
                backgroundColor: Colors.pink[50],
                color: Colors.pink,
                minHeight: 16,
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
                label: Text('Simulate +1000 Steps'),
                onPressed: () async {
                  try {
                    await ref.read(stepApiProvider).addSteps((stats['today'] ?? 0) + 1000);
                    ref.invalidate(stepStatsProvider);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')));
                  }
                },
              ),
            ],
          ),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e', style: TextStyle(color: Colors.red))),
      ),
    );
  }
}
