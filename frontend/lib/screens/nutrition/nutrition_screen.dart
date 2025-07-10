import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum25_flutter_frontend/models/food_item.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';
import 'package:sum25_flutter_frontend/services/nutrition/nutrition_api.dart';

class NutritionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(nutritionStatsProvider);
    final mealsAsync = ref.watch(mealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Nutrition', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
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
          Divider(),
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
                        calories: ((selectedFood!.macros['calories'] ?? 0) as num) * quantity / 100,
                        protein: ((selectedFood!.macros['protein'] ?? 0) as num) * quantity / 100,
                        fat: ((selectedFood!.macros['fat'] ?? 0) as num) * quantity / 100,
                        carbs: ((selectedFood!.macros['carbs'] ?? 0) as num) * quantity / 100,
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
