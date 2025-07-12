import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';

class ActivityGoalSettingsScreen extends ConsumerStatefulWidget {
  const ActivityGoalSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ActivityGoalSettingsScreen> createState() => _ActivityGoalSettingsScreenState();
}

class _ActivityGoalSettingsScreenState extends ConsumerState<ActivityGoalSettingsScreen> {
  int goal = 500;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentGoal = ref.read(activityGoalProvider);
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
        title: Text("Activity Goal", style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: "Daily Activity Goal (kcal)"),
              keyboardType: TextInputType.number,
              onChanged: (v) => goal = int.tryParse(v) ?? 500,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await ref.read(setActivityGoalProvider(goal).future);
                ref.invalidate(activityGoalProvider);
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
