import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sum25_flutter_frontend/services/activity/activity_api.dart';
import 'package:sum25_flutter_frontend/models/activity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fakeJwt = 'jwt-token';

  ActivityApi buildApi(MockClient client) => ActivityApi(client: client);

  group('addActivity', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': fakeJwt}));

    test('completes on 200', () async {
      final client = MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, endsWith('/activity')); // adjust if /base already correct
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['type'], 'run');
        return http.Response('{}', 200);
      });

      final api = buildApi(client);

      await api.addActivity(
        type: 'run',
        name: 'Morning Jog',
        duration: 30,
        intensity: 'moderate',
        calories: 200,
        location: 'Park',
      );
    });

    test('throws on non-200', () async {
      final client =
          MockClient((_) async => http.Response('error', 500));
      final api = buildApi(client);

      expect(
        () => api.addActivity(
          type: 'swim',
          name: 'Pool',
          duration: 60,
          intensity: 'high',
          calories: 400,
          location: 'Gym',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('fetchActivities', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': fakeJwt}));

    final sample = [
      {
        'id': '1',
        'type': 'run',
        'name': 'Test',
        'duration': 10,
        'intensity': 'low',
        'calories': 50,
        'location': 'Park'
      }
    ];

    test('returns list on 200', () async {
      final client = MockClient((req) async {
        expect(req.method, 'GET');
        return http.Response(jsonEncode(sample), 200);
      });

      final api = buildApi(client);
      final list = await api.fetchActivities();

      expect(list, isA<List<Activity>>());
      expect(list.length, 1);
      expect(list.first.name, 'Test');
    });

    test('filters by type param', () async {
      final client = MockClient((req) async {
        expect(req.url.queryParameters['type'], 'swim');
        return http.Response(jsonEncode(sample), 200);
      });

      final api = buildApi(client);
      await api.fetchActivities(type: 'swim');
    });

    test('returns empty on null body', () async {
      final client = MockClient((_) async => http.Response('null', 200));
      final api = buildApi(client);
      final list = await api.fetchActivities();
      expect(list, isEmpty);
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('fail', 404));
      final api = buildApi(client);
      expect(api.fetchActivities, throwsA(isA<Exception>()));
    });
  });

  group('postWorkoutReminder', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': fakeJwt}));

    test('succeeds on 200', () async {
      final client = MockClient((req) async {
        expect(req.url.path.contains('/reminder'), isTrue);
        return http.Response('{}', 200);
      });

      final api = buildApi(client);
      await api.postWorkoutReminder('/reminder', {'hello': 'world'});
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('bad', 400));
      final api = buildApi(client);
      expect(
        () => api.postWorkoutReminder('/reminder', {'x': 1}),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when JWT missing', () async {
      SharedPreferences.setMockInitialValues({});
      final client = MockClient((_) async => http.Response('{}', 200));
      final api = buildApi(client);
      expect(
        () => api.postWorkoutReminder('/p', {}),
        throwsA(isA<Exception>()),
      );
    });
  });
}
