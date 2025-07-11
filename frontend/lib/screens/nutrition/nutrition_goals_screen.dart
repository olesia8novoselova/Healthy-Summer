import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';

class GoalSettingsScreen extends ConsumerStatefulWidget {
  const GoalSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends ConsumerState<GoalSettingsScreen> {
  final _waterController = TextEditingController();
  final _calorieController = TextEditingController();

  @override
  void dispose() {
    _waterController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  void _saveGoals() async {
  final waterGoal = int.tryParse(_waterController.text);
  final calorieGoal = int.tryParse(_calorieController.text);

  if (waterGoal != null) {
    await ref.read(setWaterGoalProvider(waterGoal).future);
  }

  if (calorieGoal != null) {
    await ref.read(setCalorieGoalProvider(calorieGoal).future);
  }

  ref.invalidate(waterGoalProvider);
  ref.invalidate(calorieGoalProvider);
  ref.invalidate(todayWaterProvider);
  ref.invalidate(weeklyWaterProvider);
  ref.invalidate(nutritionStatsProvider);
  ref.invalidate(weeklyNutritionStatsProvider);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Goals updated')),
  );
}
  @override
  Widget build(BuildContext context) {
    final waterGoalAsync = ref.watch(waterGoalProvider);
    final calorieGoalAsync = ref.watch(calorieGoalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Customize Goals")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            waterGoalAsync.when(
              data: (goal) {
                _waterController.text = goal.toString();
                return TextField(
                  controller: _waterController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily Water Goal (ml)',
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error loading water goal'),
            ),
            const SizedBox(height: 16),
            calorieGoalAsync.when(
              data: (goal) {
                _calorieController.text = goal.toString();
                return TextField(
                  controller: _calorieController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily Calorie Goal',
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error loading calorie goal'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              onPressed: _saveGoals,
              child: const Text("Save Goals"),
            )
          ],
        ),
      ),
    );
  }
}
