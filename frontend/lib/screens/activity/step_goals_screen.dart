// step_goal_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';

class StepGoalSettingsScreen extends ConsumerStatefulWidget {
  const StepGoalSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StepGoalSettingsScreen> createState() => _StepGoalSettingsScreenState();
}

class _StepGoalSettingsScreenState extends ConsumerState<StepGoalSettingsScreen> {
  int goal = 10000;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentGoal = ref.read(stepGoalProvider);
    currentGoal.whenData((value) {
      setState(() {
        goal = value;
        _controller.text = value.toString();
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Step Goal", style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: "Daily Step Goal"),
              keyboardType: TextInputType.number,
              onChanged: (v) => goal = int.tryParse(v) ?? 10000,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await ref.read(setStepGoalProvider(goal).future);
                ref.invalidate(stepGoalProvider);
                Navigator.pop(context);
              },
              child: Text("Save Goal"),
            ),
          ],
        ),
      ),
    );
  }
}
