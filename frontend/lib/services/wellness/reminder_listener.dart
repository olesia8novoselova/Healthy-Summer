// lib/services/wellness/reminder_listener.dart
//
// Listens to the wellness WebSocket permanently (even when no chat screen is
// mounted) and shows local notifications for hydration / workout / challenge
// reminders sent by the backend ActivityHub.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';
import 'notification_service.dart';

/* ───────────────────────── helpers ───────────────────────── */

List<Map<String, dynamic>> _decode(dynamic raw) {
  // raw can be bytes → String → Map | List
  if (raw is Uint8List) return _decode(utf8.decode(raw));
  if (raw is String)   return _decode(jsonDecode(raw));

  if (raw is Map)      return [Map<String, dynamic>.from(raw)];
  if (raw is List)     return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  return const [];
}

/* ───────────────────────── public API ───────────────────────── */

/// Called *once* after login (see `_ReminderObserver` in `main.dart`).
///
/// Keeps the WebSocket open and registers a listener that converts every
/// `{kind:"reminder", ...}` payload into a local notification.
void attachReminderListener(ProviderContainer container) {
  final uid = container.read(userIdProvider).valueOrNull;
  if (uid == null || uid.isEmpty) return; // nothing to do

  // Keep the chat WS provider alive for the whole app-lifetime.
  final ctrl     = container.read(chatControllerProvider(uid).notifier);
  final wsStream = ctrl.wsStream; // this implicitly opens the connection

  wsStream.listen((event) {
    for (final msg in _decode(event)) {
      if (msg['kind'] != 'reminder') continue;

      switch (msg['type']) {
        case 'hydration':
          showLocal('hydro',
              '💧 Time to drink water', 'Stay hydrated!');
          break;

        case 'workout':
          showLocal('wo:${msg['title']}',
              '🏋️ Workout reminder', msg['title'] ?? 'Workout');
          break;

        case 'challenge':
          showLocal('ch:${msg['challengeId']}',
              '⏰ Challenge deadline',
              '${msg['title']} — ${msg['remaining']} left');
          break;
      }
    }
  });
}
