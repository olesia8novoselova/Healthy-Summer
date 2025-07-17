import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sum25_flutter_frontend/config.dart';
import 'package:sum25_flutter_frontend/models/challenge.dart';

class ChallengeApi {
  final String base = '$wellnessBase';

  Future<List<Challenge>> list() async {
    final token = (await _prefs()).getString('jwt_token');
    final r     = await http.get(
      Uri.parse('$base/challenges'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (r.statusCode != 200) {
      throw Exception('fetch failed: ${r.body}');
    }
    return (jsonDecode(r.body) as List)
        .map((e) => Challenge.fromJson(e))
        .toList();
  }

  Future<void> create(String title, String type, int target, {List<String> participants = const [],}) async {
    final token = (await _prefs()).getString('jwt_token');
    final res   = await http.post(
      Uri.parse('$base/challenges'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type' : 'application/json',
      },
      body: jsonEncode({'title': title, 'type': type, 'target': target,'participants': participants,  }),
    );
    if (res.statusCode != 201) {
      throw Exception('Challenge creation failed: ${res.body}');
    }
  }

  Future<void> join(String id) async {
    final token = (await _prefs()).getString('jwt_token');
    final res   = await http.post(
      Uri.parse('$base/challenges/$id/join'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Join failed: ${res.body}');
    }
  }

  Future<List<Participant>> leaderboard(String id) async {
    final token = (await _prefs()).getString('jwt_token');
    final res   = await http.get(
      Uri.parse('$base/challenges/$id/leaderboard'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Fetch leaderboard failed: ${res.body}');
    }

    final List decoded = jsonDecode(res.body) as List;
    return decoded.map((e) => Participant.fromJson(e)).toList();
  }

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();
}
