import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sum25_flutter_frontend/models/food_item.dart';
import 'package:sum25_flutter_frontend/screens/nutrition/nutrition_goals_screen.dart';
import 'package:sum25_flutter_frontend/screens/nutrition/nutrition_report_screen.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';

class NutritionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(nutritionStatsProvider);
    final mealsAsync = ref.watch(mealsProvider);
    final weeklyWater = ref.watch(weeklyWaterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Nutrition', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.insights, color: Colors.pink),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WeeklyReportScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.pink,
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddMealDialog(ref: ref),
        ),
      ),
      body: Column(
        children: [
          statsAsync.when(
            data: (stats) => Column(
              children: [
                LinearProgressIndicator(
                  value: (stats['calories'] ?? 0) / (stats['goal'] ?? 2000),
                  color: Colors.pink,
                  backgroundColor: Colors.pink[100],
                ),
                Text('${stats['calories']} / ${stats['goal']} kcal'),
              ],
            ),
            loading: () => CircularProgressIndicator(),
            error: (e, _) => Text('Failed: $e', style: TextStyle(color: Colors.red)),
          ),
          weeklyWater.when(
            data: (entries) {
              final waterGoalAsync = ref.watch(waterGoalProvider);

              return waterGoalAsync.when(
                data: (customGoal) {
                  final today = DateTime.now();
                  final todayEntry = entries.firstWhere(
                    (e) => e['date'] == today.toIso8601String().substring(0, 10),
                    orElse: () => {'total_ml': 0},
                  );

                  final double total =
                      (todayEntry['total_ml'] ?? 0).toDouble();
                  final double goal = customGoal.toDouble();

                  return Column(
                    children: [
                      SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: total / goal,
                        color: Colors.blue,
                        backgroundColor: Colors.blue[100],
                      ),
                      Text('Water: $total / $goal ml'),
                      ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('jwt_token');
                          await http.post(
                            Uri.parse('http://localhost:8080/api/nutrition/water'),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $token'
                            },
                            body: jsonEncode({'amount': 250}),
                          );
                          ref.invalidate(todayWaterProvider);
                          ref.invalidate(weeklyWaterProvider);
                        },
                        child: Text('Add 250ml Water'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.flag, color: Colors.pink),
                        title: Text("Set Goals",
                            style: TextStyle(color: Colors.black)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const GoalSettingsScreen()),
                          ).then((_) {
                            ref.invalidate(waterGoalProvider);
                            ref.invalidate(weeklyWaterProvider);
                          });
                        },
                      ),
                    ],
                  );
                },
                loading: () => CircularProgressIndicator(),
                error: (e, _) =>
                    Text('Error loading water goal: $e'),
              );
            },
            loading: () => CircularProgressIndicator(),
            error: (e, _) => Text('Failed water stat: $e'),
          ),
          Expanded(
            child: mealsAsync.when(
              data: (meals) => meals.isEmpty
                  ? Center(child: Text('No meals logged'))
                  : ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (_, index) {
                        final m = meals[index];
                        return ListTile(
                          title: Text(m.description),
                          subtitle: Text(
                            'Calories: ${m.calories}, Protein: ${m.protein}g, Fat: ${m.fat}g, Carbs: ${m.carbs}g\n${m.quantity} ${m.unit}'
                          ),
                        );
                      },
                    ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed: $e'),
            ),
          ),
        ],
      ),
    );
  }
}

class AddMealDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const AddMealDialog({required this.ref});
  @override
  ConsumerState<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends ConsumerState<AddMealDialog> {
  String query = '';
  FoodItem? selectedFood;
  double quantity = 100;
  String unit = 'g';
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(foodSearchProvider(query));

    return AlertDialog(
      title: Text('Add Meal', style: TextStyle(color: Colors.pink)),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Search food'),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 12),
            if (selectedFood == null)
              Expanded(
                child: searchAsync.when(
                  data: (foods) => foods.isEmpty
                      ? Center(child: Text('No results'))
                      : ListView.builder(
                          itemCount: foods.length,
                          itemBuilder: (context, index) {
                            final f = foods[index];
                            return ListTile(
                              title: Text(f.description),
                              subtitle:
                                  Text('Calories: ${f.macros['calories'] ?? '-'}'),
                              onTap: () => setState(() => selectedFood = f),
                            );
                          },
                        ),
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ),
            if (selectedFood != null) ...[
              Text('Selected: ${selectedFood!.description}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Quantity (g)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => quantity = double.tryParse(v) ?? 100),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(unit),
                ],
              ),
              const SizedBox(height: 8),
              if (selectedFood!.macros['calories'] != null)
                Text(
                  'Calories: ${((selectedFood!.macros['calories'] as num) * quantity / 100).toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.pink),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() => selectedFood = null),
                    child: Text('Back', style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await widget.ref.read(mealApiProvider).addMeal(
                        fdcId: selectedFood!.fdcId,
                        description: selectedFood!.description,
                        calories: ((selectedFood!.macros['calories'] ?? 0)) * quantity / 100,
                        protein: ((selectedFood!.macros['protein'] ?? 0)) * quantity / 100,
                        fat: ((selectedFood!.macros['fat'] ?? 0)) * quantity / 100,
                        carbs: ((selectedFood!.macros['carbs'] ?? 0)) * quantity / 100,
                        quantity: quantity,
                        unit: unit,
                      );
                      Navigator.pop(context);
                      widget.ref.invalidate(mealsProvider);
                      widget.ref.invalidate(nutritionStatsProvider);
                    },
                    child: Text('Add Meal', style: TextStyle(color: Colors.pink)),
                  )
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
