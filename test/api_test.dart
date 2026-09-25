import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesta_app/core/api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('login sends backend contract and reads result envelope', () async {
    final api = HestaApi(
      baseUrl: 'https://example.test/api/v1',
      accessToken: () => null,
      onUnauthorized: () async {},
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/login');
        expect(jsonDecode(request.body), {
          'email': 'user@example.test',
          'password': 'secret123',
          'deviceId': 'MOBILE_CLIENT',
          'deviceType': 'MOBILE',
        });
        return http.Response(jsonEncode({'code': 1000, 'result': {'accessToken': 'test-token', 'user': {'id': '1'}}}), 200);
      }),
    );

    final result = await api.login('user@example.test', 'secret123');
    expect(result['accessToken'], 'test-token');
  });

  test('protected request sends token and clears session on 401', () async {
    var expired = false;
    final api = HestaApi(
      baseUrl: 'https://example.test/api/v1',
      accessToken: () => 'test-token',
      onUnauthorized: () async { expired = true; },
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(jsonEncode({'code': 1001, 'message': 'Phiên hết hạn'}), 401);
      }),
    );

    await expectLater(api.homes(), throwsA(isA<ApiException>()));
    expect(expired, isTrue);
  });

  test('join code is safely encoded in query', () async {
    final api = HestaApi(
      baseUrl: 'https://example.test/api/v1',
      accessToken: () => 'test-token',
      onUnauthorized: () async {},
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/homes/join');
        expect(request.url.queryParameters['codeOrToken'], 'a+b & c');
        return http.Response(jsonEncode({'code': 1000}), 200);
      }),
    );

    await api.joinHome('a+b & c');
  });
}
