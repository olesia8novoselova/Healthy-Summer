import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sum25_flutter_frontend/config.dart';
import 'package:sum25_flutter_frontend/models/message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatApi {
  final String baseUrl;

  ChatApi({required this.baseUrl});

  // Fetch list of chat friends
  Future<List<String>> fetchChatList() async {
    final res = await http.get(Uri.parse('$baseUrl/friends'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load chat list');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => e['name'] as String).toList();
  }

  // Fetch message history with a friend
  Future<List<Message>> fetchMessages(String friend) async {
    final res = await http.get(Uri.parse('$baseUrl/messages/\$friend'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load messages');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Open WebSocket connection for real-time messaging
  Future<WebSocketChannel> connectSocket(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  // Use the passed-in userId, not the one from prefs
  String _wsHost() => apiBase.startsWith('https')
        ? apiBase.replaceFirst('https', 'wss')
        : apiBase.replaceFirst('http',  'ws');

final url = '$_wsHost/api/wellness/ws?user=$userId&token=$token';
  return WebSocketChannel.connect(Uri.parse(url));
}
  // Send a message via WebSocket
  void sendMessage(WebSocketChannel channel, Message msg) {
    print('[ChatApi] Sending message: ${msg.toJson()}');
    channel.sink.add(jsonEncode(msg.toJson()));
  }
}