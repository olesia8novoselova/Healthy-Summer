import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sum25_flutter_frontend/services/nutrition/nutrition_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NutritionApi buildApi(MockClient client) => NutritionApi(client: client);

  const fakeJwt = 'jwt123';

  group('NutritionApi.addMeal', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': fakeJwt}));

    test('completes normally on status 200', () async {
      final client = MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, endsWith('/meals'));
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['fdcId'], 111);
        return http.Response('{}', 200);
      });

      final api = buildApi(client);

      await api.addMeal(
        fdcId: 111,
        description: 'Test food',
        calories: 1,
        protein: 1,
        fat: 1,
        carbs: 1,
        quantity: 1,
        unit: 'g',
      );
    });

    test('throws Exception on non-200', () async {
      final client = MockClient((_) async => http.Response('fail', 500));
      final api = buildApi(client);

      expect(
        () => api.addMeal(
          fdcId: 1,
          description: 'x',
          calories: 1,
          protein: 1,
          fat: 1,
          carbs: 1,
          quantity: 1,
          unit: 'g',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('NutritionApi.fetchWeeklyStats', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': fakeJwt}));

    test('returns decoded list on 200', () async {
      final payload = [
        {'day': 'Mon', 'calories': 100},
        {'day': 'Tue', 'calories': 200},
      ];

      final client = MockClient((req) async {
        expect(req.method, 'GET');
        expect(req.url.path, endsWith('/stats/weekly'));
        return http.Response(jsonEncode(payload), 200);
      });

      final api = buildApi(client);
      final list = await api.fetchWeeklyStats();

      expect(list, isA<List<Map<String, dynamic>>>());
      expect(list.length, 2);
      expect(list[0]['day'], 'Mon');
    });

    test('throws Exception on non-200', () async {
      final client = MockClient((_) async => http.Response('bad', 404));
      final api = buildApi(client);

      expect(api.fetchWeeklyStats, throwsA(isA<Exception>()));
    });
  });
}
