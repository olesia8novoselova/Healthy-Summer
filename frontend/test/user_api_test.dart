import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sum25_flutter_frontend/services/user/user_api.dart';
import 'package:sum25_flutter_frontend/models/friend.dart';
import 'package:sum25_flutter_frontend/models/achievement.dart';
import 'package:sum25_flutter_frontend/models/friend_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Helper that wires a [MockClient] into [UserApi].
  UserApi buildApi(MockClient client) => UserApi(httpClient: client);

  group('UserApi happy paths', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'jwt_token': 'fake_jwt'});
    });

    test('fetchProfile returns decoded map', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/profile'));
        return http.Response(jsonEncode({'id': 'u1', 'name': 'Jane'}), 200);
      });

      final profile = await buildApi(client).fetchProfile();
      expect(profile['name'], equals('Jane'));
    });

    test('fetchFriends returns a List<Friend>', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/friends'));
        return http.Response(
          jsonEncode([
            {'id': '1', 'name': 'Alice'},
            {'id': '2', 'name': 'Bob'}
          ]),
          200,
        );
      });

      final friends = await buildApi(client).fetchFriends();
      expect(friends, isA<List<Friend>>());
      expect(friends.length, 2);
      expect(friends.first.name, 'Alice');
    });

    test('fetchAchievements returns a List<Achievement>', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/achievements'));
        return http.Response(
          jsonEncode([
            {'id': 'a1', 'title': 'Winner'},
            {'id': 'a2', 'title': 'Finisher'}
          ]),
          200,
        );
      });

      final ach = await buildApi(client).fetchAchievements();
      expect(ach, isA<List<Achievement>>());
      expect(ach.first.title, 'Winner');
    });

    test('sendFriendRequest succeeds on 200', () async {
      final client = MockClient((req) async {
        expect(req.method, equals('POST'));
        expect(req.url.path, endsWith('/friends/request'));
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['email'], 'foo@bar.com');
        return http.Response('{}', 200);
      });

      await buildApi(client).sendFriendRequest('foo@bar.com');
    });

    test('fetchFriendRequests parses list', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/friends/requests'));
        return http.Response(
          jsonEncode([
            {
              'id': 'r1',
              'fromUser': {'id': 'u2', 'name': 'Bob'},
              'status': 'pending'
            }
          ]),
          200,
        );
      });

      final reqs = await buildApi(client).fetchFriendRequests();
      expect(reqs, isA<List<FriendRequest>>());
      expect(reqs.single.id, 'r1');
    });
  });

  group('UserApi error paths', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': 'fake_jwt'}));

    test('fetchProfile throws when backend != 200', () async {
      final client = MockClient(
          (req) async => http.Response(jsonEncode({'error': 'Boom'}), 500));

      expect(() => buildApi(client).fetchProfile(), throwsA(isA<Exception>()));
    });

    test('sendFriendRequest throws on non-200', () async {
      final client = MockClient((req) async => http.Response('bad', 400));
      expect(() => buildApi(client).sendFriendRequest('x@y.z'),
          throwsA(isA<Exception>()));
    });

    test('methods throw when JWT is missing', () async {
      SharedPreferences.setMockInitialValues({}); // cleared token
      final client = MockClient((_) async => http.Response('{}', 200));

      expect(() => buildApi(client).fetchProfile(), throwsA(isA<Exception>()));
    });
  });
}
