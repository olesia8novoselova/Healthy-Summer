import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';                 // ⬅️ new
import '../../services/providers.dart';

class AddWorkoutReminderDialog extends ConsumerStatefulWidget {
  const AddWorkoutReminderDialog({super.key});

  @override
  ConsumerState<AddWorkoutReminderDialog> createState() =>
      _AddWorkoutReminderDialogState();
}

class _AddWorkoutReminderDialogState
    extends ConsumerState<AddWorkoutReminderDialog> {
  // ───── state that changes after init ─────
  late int weekday;
  late TextEditingController timeCtl;
  late TextEditingController titleCtl;
  bool loading = false;

  // ───── inject “+2 minutes” defaults here ─────
  @override
  void initState() {
    super.initState();

    final now = DateTime.now().add(const Duration(minutes: 2));
    weekday   = now.weekday % 7;                       // Mon=0 … Sun=6
    timeCtl   = TextEditingController(
        text: DateFormat('HH:mm').format(now));        // e.g. 15 : 24
    titleCtl  = TextEditingController(text: 'Workout');
  }

  @override
  void dispose() {
    timeCtl.dispose();
    titleCtl.dispose();
    super.dispose();
  }

  // ───── UI  ─────
  @override
  Widget build(BuildContext ctx) {
    return AlertDialog(
      title: const Text('New Workout Reminder',
          style: TextStyle(color: Colors.pink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: weekday,
            items: List.generate(
              7,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                ),
              ),
            ),
            onChanged: (v) => setState(() => weekday = v!),
          ),
          TextField(
            controller: timeCtl,
            decoration: const InputDecoration(
              labelText: 'Time (HH:MM)',
              filled: true,
            ),
          ),
          TextField(
            controller: titleCtl,
            decoration: const InputDecoration(
              labelText: 'Title',
              filled: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: Colors.pink)),
        ),
        TextButton(
          onPressed: loading
              ? null
              : () async {
                  setState(() => loading = true);
                  try {
                    await ref.read(activityApiProvider).postWorkoutReminder(
                      '/schedule/workouts',
                      {
                        'weekday': weekday,
                        'time': timeCtl.text,
                        'title': titleCtl.text,
                      },
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Workout reminder saved ✅')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  } finally {
                    setState(() => loading = false);
                  }
                },
          child: loading
              ? const CircularProgressIndicator()
              : const Text('Save', style: TextStyle(color: Colors.pink)),
        ),
      ],
    );
  }
}
