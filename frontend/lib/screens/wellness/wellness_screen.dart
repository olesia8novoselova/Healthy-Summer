import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum25_flutter_frontend/screens/wellness/leaderboard_screen.dart';
import 'package:sum25_flutter_frontend/screens/wellness/messaging_screen.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';


class WellnessScreen extends ConsumerWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(friendActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.pink),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events,color: Colors.pink),
            tooltip: 'Leaderboards',
            onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LeaderboardScreen())),
          ),

          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.pink),
            onPressed: () async {
              final userId = await ref.read(userIdProvider.future);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => MessagingScreen(userId:userId), 
                ),
              );
            },
            tooltip: 'Chats',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Activity Feed",
            style: TextStyle(
              fontSize: 20,
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          activitiesAsync.when(
            data: (activities) {
              if (activities.isEmpty) {
                return const Center(child: Text("No recent activity", style: TextStyle(color: Colors.pink)));
              }
              return Column(
                children: activities.map((item) => Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.pink[50],
                          radius: 28,
                          child: const Icon(Icons.person, color: Colors.pink, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink),
                              ),
                              const SizedBox(height: 4),
                              Text(item.message, style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(item.createdAt),
                                style: TextStyle(fontSize: 13, color: Colors.pink[200]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final userId = await ref.read(userIdProvider.future);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => MessagingScreen(userId: userId, friendId: item.userId, friendName: item.userName),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Message', style: TextStyle(color: Colors.pink)),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Failed to load feed: $err", style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
       floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => _CreateStatusDialog(ref: ref),
          );
        },
      ),
    );
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}

class _CreateStatusDialog extends StatefulWidget {
  final WidgetRef ref;
  const _CreateStatusDialog({required this.ref});

  @override
  State<_CreateStatusDialog> createState() => _CreateStatusDialogState();
}

class _CreateStatusDialogState extends State<_CreateStatusDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Post a Status", style: TextStyle(color: Colors.pink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Feeling great today! 🌞",
              hintStyle: TextStyle(
                color: Colors.pink.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.pink),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text("Cancel", style: TextStyle(color: Colors.pink)),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Post", style: TextStyle(color: Colors.pink)),
          onPressed: _loading
              ? null
              : () async {
                  final msg = _controller.text.trim();
                  if (msg.isEmpty) return;

                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  try {
                    await widget.ref
                        .read(wellnessApiProvider)
                        .postWellnessActivity(
                          type: "status",
                          message: msg,
                        );
                    widget.ref.invalidate(friendActivitiesProvider);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Status shared with friends 🎉")));
                  } catch (e) {
                    setState(() => _error = e.toString());
                  } finally {
                    setState(() => _loading = false);
                  }
                },
        ),
      ],
    );
  }
}