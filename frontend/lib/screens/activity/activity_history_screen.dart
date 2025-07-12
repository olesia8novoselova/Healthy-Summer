import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';

class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  String? selectedType;

  final activityTypes = [
    null,
    'running',
    'swimming',
    'cycling',
    'yoga',
  ];

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider(selectedType));
    final weeklyActivityAsync = ref.watch(weeklyActivityStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Dropdown filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String?>(
              value: selectedType,
              hint: const Text('Filter by type'),
              items: activityTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type == null
                      ? 'All'
                      : type[0].toUpperCase() + type.substring(1),
                    style: const TextStyle(color: Colors.pink),
                  ),
                );
              }).toList(),
              onChanged: (type) => setState(() {
                selectedType = type;
              }),
            ),
          ),
          // Activity list
          Expanded(
            child: activitiesAsync.when(
              data: (activities) => activities.isEmpty
                  ? const Center(child: Text('No activities found', style: TextStyle(color: Colors.pink)))
                  : ListView(
                      children: activities.map((a) => ListTile(
                        title: Text('${a.name.isNotEmpty ? a.name : a.type} (${a.type})', style: const TextStyle(color: Colors.pink)),
                        subtitle: Text(
                          '${a.duration} min, ${a.calories} kcal, ${a.location}\n${a.performedAt.toLocal()}'
                        ),
                      )).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
          const Divider(),
          // Weekly summary & insights
          weeklyActivityAsync.when(
            data: (raw) {
              // Ensure numeric types
              final days = raw.map((e) {
                final date = e['date'] as String;
                final calVal = e['calories'];
                final durVal = e['duration'];
                final calories = calVal is String ? int.tryParse(calVal) ?? 0 : (calVal as num).toInt();
                final duration = durVal is String ? int.tryParse(durVal) ?? 0 : (durVal as num).toInt();
                return {'date': date, 'calories': calories, 'duration': duration};
              }).toList();

              if (days.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No weekly activity data', style: TextStyle(color: Colors.pink)),
                );
              }

              final caloriesList = days.map((d) => d['calories'] as int).toList();
              final durationList = days.map((d) => d['duration'] as int).toList();
              final avgCalories = (caloriesList.reduce((a, b) => a + b) / caloriesList.length).round();
              final avgDuration = (durationList.reduce((a, b) => a + b) / durationList.length).round();

              final maxIdx = caloriesList.indexWhere((v) => v == caloriesList.reduce((a, b) => a > b ? a : b));
              final minIdx = caloriesList.indexWhere((v) => v == caloriesList.reduce((a, b) => a < b ? a : b));
              String weekday(DateTime dt) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][dt.weekday - 1];
              final maxDay = weekday(DateTime.parse(days[maxIdx]['date'] as String));
              final minDay = weekday(DateTime.parse(days[minIdx]['date'] as String));

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🧠 Weekly Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('• Avg Calories Burned: $avgCalories kcal/day'),
                    Text('• Avg Duration: $avgDuration min/day'),
                    Text('• Most Active Day: $maxDay (${caloriesList[maxIdx]} kcal)'),
                    Text('• Least Active Day: $minDay (${caloriesList[minIdx]} kcal)'),
                    const Divider(),
                    ...days.map((d) => ListTile(
                      title: Text(d['date'] as String),
                      subtitle: Text('Calories: ${d['calories']}, Duration: ${d['duration']} min'),
                    )),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load weekly stats: $e', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}
