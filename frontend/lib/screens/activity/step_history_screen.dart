import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';

class StepHistoryScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<StepHistoryScreen> createState() => _StepHistoryScreenState();
}

class _StepHistoryScreenState extends ConsumerState<StepHistoryScreen> {
  int selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(stepHistoryProvider(selectedDays));
    final statsAsync = ref.watch(stepStatsProvider);


    return Scaffold(
      appBar: AppBar(
        title: Text('Step History', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          statsAsync.when(
            data: (stats) => Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16, bottom: 8),
              child: Column(
                children: [
                  Text('Today: ${stats['today']} / ${stats['goal']} steps',
                      style: TextStyle(fontSize: 18, color: Colors.pink)),
                  SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: stats['goal'] > 0 ? (stats['today'] / stats['goal']).clamp(0, 1).toDouble() : 0,
                    minHeight: 7,
                    color: Colors.pink,
                    backgroundColor: Colors.pink[50],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weekly: ${stats['weekly_total']}', style: TextStyle(color: Colors.pink)),
                      Text('Monthly: ${stats['monthly_total']}', style: TextStyle(color: Colors.pink)),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Container(), // or show error
          ),
          DropdownButton<int>(
            value: selectedDays,
            items: [7, 30, 90]
                .map((d) => DropdownMenuItem(value: d, child: Text('Last $d days')))
                .toList(),
            onChanged: (v) => setState(() => selectedDays = v!),
          ),
          Expanded(
            child: historyAsync.when(
              data: (history) => history.isEmpty
                  ? Center(child: Text('No steps recorded', style: TextStyle(color: Colors.pink)))
                  : ListView(
                      children: history
                          .map((d) => ListTile(
                                title: Text('${d['day']}'),
                                trailing: Text('${d['steps']} steps', style: TextStyle(color: Colors.pink)),
                              ))
                          .toList(),
                    ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e', style: TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
