import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sum25_flutter_frontend/services/activity/step_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const jwt = 'token123';

  StepApi buildApi(MockClient client) => StepApi(client: client);

  group('addSteps', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': jwt}));

    test('completes on 200', () async {
      final client = MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, endsWith('/steps'));
        expect(jsonDecode(req.body)['steps'], 500);
        return http.Response('{}', 200);
      });

      await buildApi(client).addSteps(500);
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('bad', 400));
      expect(buildApi(client).addSteps(1), throwsA(isA<Exception>()));
    });
  });

  group('fetchStepStats', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': jwt}));

    test('returns decoded map on 200', () async {
      final payload = {'today': 8000, 'week': 56000};
      final client = MockClient((_) async => http.Response(jsonEncode(payload), 200));

      final stats = await buildApi(client).fetchStepStats();
      expect(stats['today'], 8000);
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('err', 500));
      expect(buildApi(client).fetchStepStats, throwsA(isA<Exception>()));
    });
  });

  group('fetchStepHistory', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': jwt}));

    final sample = [
      {'day': 'Mon', 'steps': 7000},
      {'day': 'Tue', 'steps': 8000}
    ];

    test('returns list on 200', () async {
      final client = MockClient((req) async {
        expect(req.method, 'GET');
        expect(req.url.queryParameters['days'], '14');
        return http.Response(jsonEncode(sample), 200);
      });

      final list = await buildApi(client).fetchStepHistory(days: 14);
      expect(list.length, 2);
      expect(list.first['day'], 'Mon');
    });

    test('throws on non-200', () async {
      final client = MockClient((_) async => http.Response('fail', 404));
      expect(buildApi(client).fetchStepHistory, throwsA(isA<Exception>()));
    });
  });
}
