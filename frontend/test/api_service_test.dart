import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sum25_flutter_frontend/services/api_service.dart';

void main() {

  ApiService build(MockClient client) => ApiService(client: client);

  group('ApiService.healthCheck', () {
    test('returns decoded JSON on 200', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/health'));
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final svc = build(client);
      final result = await svc.healthCheck();

      expect(result['status'], equals('ok'));
    });

    test('throws ApiException on non-200', () async {
      final client = MockClient((_) async => http.Response('err', 500));
      final svc = build(client);

      expect(svc.healthCheck, throwsA(isA<ApiException>()));
    });

    test('throws ApiException on client error', () async {
      final client = MockClient((_) async => throw http.ClientException('boom'));
      final svc = build(client);

      expect(svc.healthCheck, throwsA(isA<ApiException>()));
    });
  });

  group('ApiService.ping', () {
    test('returns decoded JSON on 200', () async {
      final client = MockClient((req) async {
        expect(req.url.path, endsWith('/api/ping'));
        return http.Response(jsonEncode({'pong': true}), 200);
      });

      final svc = build(client);
      final result = await svc.ping();

      expect(result['pong'], isTrue);
    });

    test('throws ApiException on non-200', () async {
      final client = MockClient((_) async => http.Response('oops', 404));
      final svc = build(client);

      expect(svc.ping, throwsA(isA<ApiException>()));
    });

    test('throws ApiException on client error', () async {
      final client = MockClient((_) async => throw http.ClientException('network down'));
      final svc = build(client);

      expect(svc.ping, throwsA(isA<ApiException>()));
    });
  });

  test('dispose closes the underlying client (no exception)', () {
    final client = MockClient((_) async => http.Response('{}', 200));
    final svc = build(client);

    expect(svc.dispose, returnsNormally);
  });
}
