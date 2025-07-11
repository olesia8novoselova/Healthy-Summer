import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';

class WeeklyReportScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = ref.watch(weeklyNutritionStatsProvider);
    final weeklyWater = ref.watch(weeklyWaterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Nutrition Report', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
      ),
      body: weeklyStats.when(
        data: (days) {
          if (days.isEmpty) {
            return Center(child: Text('No data for this week'));
          }


          final calorieValues = days.map((d) => d['calories'] as num).toList();
          final proteinValues = days.map((d) => d['protein'] as num).toList();
          final dayNames = days.map((d) => DateTime.parse(d['date'])).toList();

          final avgCalories = (calorieValues.reduce((a, b) => a + b) / calorieValues.length).round();
          final avgProtein = (proteinValues.reduce((a, b) => a + b) / proteinValues.length).round();

          final maxIndex = calorieValues.indexWhere((v) => v == calorieValues.reduce((a, b) => a > b ? a : b));
          final minIndex = calorieValues.indexWhere((v) => v == calorieValues.reduce((a, b) => a < b ? a : b));
          final deficitDays = calorieValues.where((v) => v < 2000).length;

          final weekday = (DateTime dt) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][dt.weekday - 1];
          final maxDay = weekday(dayNames[maxIndex]);
          final minDay = weekday(dayNames[minIndex]);

          return weeklyWater.when(
            data: (waterList) {
              debugPrint('Weekly water raw body: $waterList');
              
              final waterValues = waterList.map((d) => (d['total_ml'] ?? 0) as num).toList();
              final avgWater = (waterValues.reduce((a, b) => a + b) / waterValues.length).round();
              final lowDays = waterValues.where((v) => v < 2000).length;

              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🧠 Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 6),
                        Text('• Average Calories: $avgCalories kcal/day'),
                        Text('• Average Protein: $avgProtein g/day'),
                        Text('• Highest Intake: $maxDay (${calorieValues[maxIndex].round()} kcal)'),
                        Text('• Lowest Intake: $minDay (${calorieValues[minIndex].round()} kcal)'),
                        Text('• Deficit Days (< 2000 kcal): $deficitDays'),
                        Text('💧 Hydration'),
                        Text('• Average Water Intake: $avgWater ml/day'),
                        Text('• Days under 2000ml: $lowDays'),
                      ],
                    ),
                  ),
                  Divider(),
                  ...days.map((day) => ListTile(
                    title: Text(day['date'] ?? 'Unknown Date'),
                    subtitle: Text(
                      'Calories: ${day['calories']}, Protein: ${day['protein']}g, Fat: ${day['fat']}g, Carbs: ${day['carbs']}g',
                    ),
                  )),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load water data: $e')),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load report: $e')),
      ),
    );
  }
}
