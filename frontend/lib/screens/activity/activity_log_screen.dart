import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum25_flutter_frontend/screens/activity/activity_goals_screen.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';

const caloriesPerMinute = {
  'running': 10.0,
  'swimming': 8.0,
  'cycling': 7.0,
  'yoga': 4.0,
};

double calculateCalories(String? type, int duration) {
  final perMin = caloriesPerMinute[type ?? ''] ?? 6.0;
  return perMin * duration;
}

class ActivityLogScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider(null));
    final goalAsync = ref.watch(activityGoalProvider);
    final todayCaloriesAsync = ref.watch(todayActivityCaloriesProvider);
    final goalReached = ref.watch(activityGoalReachedProvider);
    final alreadyNotified = ref.watch(goalNotifiedProvider);

    // 🔔 Show share dialog once when goal is reached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (goalReached && !alreadyNotified) {
        ref.read(goalNotifiedProvider.notifier).state = true;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("🎉 Activity Goal Reached!"),
            content: Text("You reached your activity goal today! Want to share it with friends?"),
            actions: [
              TextButton(
                child: Text("Not now"),
                onPressed: () => Navigator.pop(context),
                
                style: TextButton.styleFrom(foregroundColor: Colors.pink),
              ),
              TextButton(
                child: Text("Share"),
                onPressed: () async {
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  await Future.delayed(const Duration(milliseconds: 200)); 
                  try {
                    await ref.read(wellnessApiProvider).postWellnessActivity(
                      type: "activity_goal",
                      message: "I just hit my daily activity goal! 💪",
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Shared to friends 🎉")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to share: $e")),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.pink),
              )
            ],
          ),
        );
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Log', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.pink),
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => showDialog(
          context: context,
          builder: (ctx) => AddActivityDialog(ref: ref),
        ),
      ),
      body: Column(
        children: [
          goalAsync.when(
            data: (goal) {
              return todayCaloriesAsync.when(
                data: (todayCals) {
                  final progress = (todayCals / goal).clamp(0.0, 1.0);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 14,
                          backgroundColor: Colors.pink[100],
                          color: Colors.pink,
                        ),
                      ),
                      Text(
                        'Today: $todayCals / $goal kcal',
                        style: TextStyle(color: Colors.pink),
                      ),
                      SizedBox(height: 8),
                    ],
                  );
                },
                loading: () => CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              );
            },
            loading: () => CircularProgressIndicator(),
            error: (e, _) => Text('Goal Error: $e'),
          ),
          Expanded(
            child: activitiesAsync.when(
              data: (activities) => activities.isEmpty
                  ? Center(child: Text('No activities yet', style: TextStyle(color: Colors.pink)))
                  : ListView(
                      children: activities
                          .map((a) => ListTile(
                                title: Text(
                                  '${a.name.isNotEmpty ? a.name : a.type} (${a.type})',
                                  style: TextStyle(color: Colors.pink),
                                ),
                                subtitle: Text(
                                  '${a.duration} min, ${a.calories} kcal, ${a.location}, '
                                  'Intensity: ${a.intensity}\n${a.performedAt.toLocal()}',
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e', style: TextStyle(color: Colors.red))),
            ),
          ),
          ListTile(
            leading: Icon(Icons.flag, color: Colors.pink),
            title: Text("Set Activity Goal", style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivityGoalSettingsScreen()),
              ).then((_) {
                ref.invalidate(activityGoalProvider);
                ref.invalidate(todayActivityCaloriesProvider);
              });
            },
          ),
        ],
      ),
    );
  }
}


class AddActivityDialog extends StatefulWidget {
  final WidgetRef ref;
  const AddActivityDialog({required this.ref, super.key});

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _durationController = TextEditingController();
  final _intensityController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _locationController = TextEditingController();
  final List<String> activityTypes = [
    'running', 'swimming', 'cycling', 'yoga'
  ];
  String? _selectedType;
  final _nameController = TextEditingController();

  double? _calories;

  String? _error;
  bool _loading = false;

  void _updateCalories() {
    final duration = int.tryParse(_durationController.text) ?? 0;
    setState(() {
      _calories = calculateCalories(_selectedType, duration);
    });
  }

  @override
  void initState() {
    super.initState();
    _durationController.addListener(_updateCalories);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _intensityController.dispose();
    _caloriesController.dispose();
    _locationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    final ref = widget.ref;
    return AlertDialog(
      title: Text('Add Activity', style: TextStyle(color: Colors.pink)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Activity Name',
                labelStyle: TextStyle(color: Colors.pink),
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: activityTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type[0].toUpperCase() + type.substring(1)),
                      ))
                  .toList(),
               onChanged: (val) {
                  setState(() => _selectedType = val);
                  _updateCalories();
                },
              decoration: InputDecoration(labelText: 'Activity Type', labelStyle: TextStyle(color: Colors.pink)),
            ),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration (min)',
                labelStyle: TextStyle(color: Colors.pink),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _intensityController,
              decoration: InputDecoration(
                labelText: 'Intensity (1-10)',
                labelStyle: TextStyle(color: Colors.pink),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 8),
            Text('Calories Burned: ${_calories?.toStringAsFixed(0) ?? "-"}',
                style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                labelStyle: TextStyle(color: Colors.pink),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () async {
            setState(() {
              _loading = true;
              _error = null;
            });
            try {
              await widget.ref.read(activityApiProvider).addActivity(
                type: _selectedType!,
                name: _nameController.text,
                duration: int.tryParse(_durationController.text) ?? 0,
                intensity: _intensityController.text,
                calories: _calories?.toInt() ?? 0,
                location: _locationController.text,
              );
              Navigator.pop(context);
              widget.ref.refresh(activitiesProvider(null));
            } catch (e) {
              setState(() {
                _error = e.toString().replaceFirst('Exception:', '').trim();
              });
            } finally {
              setState(() { _loading = false; });
            }
          },
          child: _loading
              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Add', style: TextStyle(color: Colors.pink)),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.pink)),
        ),
      ],
    );
  }
}


