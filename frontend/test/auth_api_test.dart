import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sum25_flutter_frontend/services/user/auth_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AuthApi buildApi(MockClient client) => AuthApi(client: client);

  group('AuthApi.login()', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('returns token & saves it on 200', () async {
      const fakeToken = 'abc123';

      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/login'));
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['email'], 'a@b.c');
        expect(body['password'], 'pw');
        return http.Response(jsonEncode({'token': fakeToken}), 200);
      });

      final api = buildApi(client);
      final token = await api.login('a@b.c', 'pw');

      expect(token, fakeToken);

      // Confirm it was persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_token'), fakeToken);
    });

    test('throws on non-200', () async {
      final client =
          MockClient((_) async => http.Response(jsonEncode({'error': 'bad'}), 401));
      final api = buildApi(client);

      expect(() => api.login('x@y.z', 'pw'), throwsA(isA<Exception>()));
    });
  });

  group('AuthApi.register()', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('returns token & saves it on 200', () async {
      const fakeToken = 'newbie';

      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/register'));
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['name'], 'Jane');
        return http.Response(jsonEncode({'token': fakeToken}), 200);
      });

      final api = buildApi(client);
      final token = await api.register('Jane', 'j@e.com', 'secret');

      expect(token, fakeToken);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_token'), fakeToken);
    });

    test('throws on non-200', () async {
      final client =
          MockClient((_) async => http.Response('nope', 500));
      final api = buildApi(client);

      expect(() => api.register('n', 'e', 'p'), throwsA(isA<Exception>()));
    });
  });

  group('AuthApi.logout() & getStoredToken()', () {
    const savedToken = 'stored';

    setUp(() {
      SharedPreferences.setMockInitialValues({'jwt_token': savedToken});
    });

    test('logout removes token from prefs', () async {
      final api = buildApi(MockClient((_) async => http.Response('{}', 200)));

      await api.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_token'), isNull);
    });

    test('getStoredToken returns the existing token', () async {
      final api = buildApi(MockClient((_) async => http.Response('{}', 200)));
      final token = await api.getStoredToken();

      expect(token, savedToken);
    });
  });
}
