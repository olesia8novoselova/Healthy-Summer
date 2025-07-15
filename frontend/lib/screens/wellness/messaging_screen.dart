import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum25_flutter_frontend/models/message.dart';
import 'package:sum25_flutter_frontend/services/providers.dart';

class _ChatSession {
  final messages = <Message>[];
  final seenIds  = <String>{};
  bool historyLoaded = false;
}

class _ChatSessionNotifier extends StateNotifier<_ChatSession> {
  _ChatSessionNotifier() : super(_ChatSession());
  void add(Message m)           { if (state.seenIds.add(m.id)) state.messages.add(m); }
  void addMany(Iterable<Message> l) { l.forEach(add); }
  void markHistoryLoaded()      { state.historyLoaded = true; }
}

final chatSessionProvider =
    StateNotifierProvider.family<_ChatSessionNotifier, _ChatSession, String>(
  (ref, friendId) => _ChatSessionNotifier(),
);

class MessagingScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? friendId;
  final String? friendName;
  const MessagingScreen({
    required this.userId,
    this.friendId,
    this.friendName,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  final _controller = TextEditingController();

  bool _belongs(Message m) =>
      (m.senderId   == widget.userId   && m.receiverId == widget.friendId) ||
      (m.senderId   == widget.friendId && m.receiverId == widget.userId);

  List<Message> _decode(dynamic p) {
    if (p is Uint8List) return _decode(utf8.decode(p));

    if (p is String) {
      final data = jsonDecode(p);
      return _decode(data);
    }

    if (p is Map) {
      return [Message.fromJson(Map<String, dynamic>.from(p))];
    }

    if (p is List) {
      return p.map<Message>((e) =>
          Message.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    return const [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.friendId == null) {
      final friends = ref.watch(chatListProvider);
      return Scaffold(
        appBar: _bar(const Text('Chats')),
        body: friends.when(
          data: (f) => f.isEmpty
              ? const Center(child: Text('No chats yet', style: _pink18))
              : ListView(
                  children: f.map((u) => ListTile(
                    leading: const Icon(Icons.person, color: Colors.pink),
                    title : Text(u['name'] ?? '', style: const TextStyle(color: Colors.pink)),
                    onTap : () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => MessagingScreen(
                              userId: widget.userId,
                              friendId: u['id'],
                              friendName: u['name'],
                            ))),
                  )).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: _red)),
        ),
      );
    }

    final sess     = ref.watch(chatSessionProvider(widget.friendId!));
    final sessCtl  = ref.read(chatSessionProvider(widget.friendId!).notifier);

    ref.watch(messagesProvider(widget.friendId!)).whenData((hist) {
      if (!sess.historyLoaded) {
        sessCtl.addMany(hist.where(_belongs));
        sessCtl.markHistoryLoaded();
      }
    });

    final chCtrl   = ref.read(chatControllerProvider(widget.userId).notifier);
    final wsStream = chCtrl.wsStream;      

    return Scaffold(
      appBar: _bar(Text('Chat with ${widget.friendName ?? widget.friendId}')),
      body: Column(
        children: [
          Expanded(
            
            child: StreamBuilder(
              stream: wsStream,
              builder: (_, snap) {
                if (snap.hasData) sessCtl.addMany(_decode(snap.data).where(_belongs));
                return ListView(
                  key: PageStorageKey(widget.friendId),
                  padding: const EdgeInsets.all(16),
                  children: sess.messages.map(_bubble).toList(),
                );
              },
            ),
          ),
          _input(chCtrl, sessCtl),
        ],
      ),
    );
  }

  AppBar _bar(Widget t) => AppBar(
        title: DefaultTextStyle.merge(style: const TextStyle(color: Colors.pink), child: t),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.pink),
        elevation: 0,
      );

  Widget _bubble(Message m) {
    final me   = m.senderId == widget.userId;
    final nick = me ? 'You' : (widget.friendName ?? m.senderId);
    final bg   = me ? Colors.pink[100] : Colors.pink[50];

    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(nick, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(m.text, style: TextStyle(color: Colors.pink[900])),
          ),
        ],
      ),
    );
  }

  Widget _input(ChatController ws, _ChatSessionNotifier sess) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pink)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.pink),
              onPressed: () {
                final txt = _controller.text.trim();
                if (txt.isEmpty) return;

                final msg = Message(
                  id: UniqueKey().toString(),
                  senderId: widget.userId,
                  receiverId: widget.friendId!,
                  text: txt,
                  createdAt: DateTime.now().toUtc(),
                );

                sess.add(msg);       // optimistic
                ws.send(msg.toJson());
                _controller.clear();
              },
            ),
          ],
        ),
      );
}

const _pink18 = TextStyle(color: Colors.pink, fontSize: 18);
const _red    = TextStyle(color: Colors.red);
