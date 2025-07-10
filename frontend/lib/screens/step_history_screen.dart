import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';

class StepHistoryScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<StepHistoryScreen> createState() => _StepHistoryScreenState();
}

class _StepHistoryScreenState extends ConsumerState<StepHistoryScreen> {
  int selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(stepHistoryProvider(selectedDays));

    return Scaffold(
      appBar: AppBar(
        title: Text('Step History', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
