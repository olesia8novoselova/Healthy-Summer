import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initLocalNotif() async {
  await _plugin.initialize(
    const InitializationSettings(
      android : AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS     : DarwinInitializationSettings(),
      macOS   : DarwinInitializationSettings(),
      linux   : LinuxInitializationSettings(defaultActionName: 'OK'),
    ),
  );
}

/// Show the toast **or** fall back to an in-app SnackBar on platforms

void showLocal(String id, String title, String body) async {
  try {
    await _plugin.show(
      id.hashCode,
      title,
      body,
      const NotificationDetails(
        android : AndroidNotificationDetails('reminders', 'Reminders'),
        iOS     : DarwinNotificationDetails(),
      ),
    );
  } catch (_) {
    // ───── fallback ─────
    final ctx = _navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text('$title\n$body')));
    }
  }
}

/// gives SnackBar fallback a BuildContext even when no page is open
final _navigatorKey = GlobalKey<NavigatorState>();
GlobalKey<NavigatorState> get rootNavigatorKey => _navigatorKey;
