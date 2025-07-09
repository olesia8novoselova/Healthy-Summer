import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart'; // adjust as needed
import '../models/activity.dart';

class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  String? selectedType; // For filter

  final activityTypes = [
    null, // For "All"
    'running',
    'swimming',
    'cycling',
    'yoga',
    // ...add more if you support them
  ];

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider(selectedType));

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
          Expanded(
            child: activitiesAsync.when(
              data: (activities) => activities.isEmpty
                  ? const Center(child: Text('No activities found', style: TextStyle(color: Colors.pink)))
                  : ListView(
                      children: activities.map((a) => ListTile(
                        title: Text('${a.type} (${a.intensity})', style: const TextStyle(color: Colors.pink)),
                        subtitle: Text('${a.duration} min, ${a.calories} kcal, ${a.location}\n${a.performedAt.toLocal()}'),
                      )).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
