import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syna/core/exceptions/app_exception.dart';
import 'package:syna/features/authentication/data/api_auth_repository.dart';

import '../../support/in_memory_token_storage.dart';

const _userJson = {
  'id': 'u-0000-0001',
  'email': 'toan@syna.dev',
  'fullName': 'Toan',
  'phoneNumber': '0123456789',
};

Map<String, dynamic> _authEnvelope(String accessToken) => {
  'code': 1000,
  'message': 'Success',
  'result': {
    'accessToken': accessToken,
    'refreshToken': 'refresh-2',
    'tokenType': 'Bearer',
    'expiresIn': 86400,
    'user': _userJson,
  },
};

void main() {
  late HttpServer server;
  late ApiAuthRepository repository;
  late InMemoryTokenStorage storage;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      int statusCode = 200;
      Object body;
      if (path == '/api/v1/auth/login') {
        final requestBody =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        if (requestBody['password'] == 'wrong') {
          statusCode = 401;
          body = {
            'code': 1006,
            'message': 'Sai email hoặc mật khẩu',
            'result': null,
          };
        } else {
          body = _authEnvelope('access-1');
        }
      } else {
        body = {'code': 1000, 'message': 'Success', 'result': null};
      }
      request.response
        ..statusCode = statusCode
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await request.response.close();
    });

    storage = InMemoryTokenStorage();
    repository = ApiAuthRepository(
      dio: Dio(
        BaseOptions(baseUrl: 'http://${server.address.address}:${server.port}'),
      ),
      tokenStorage: storage,
    );
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('login thành công lưu token và trả session', () async {
    final session = await repository.login(
      email: 'toan@syna.dev',
      password: 'secret123',
    );

    expect(session.userId, 'u-0000-0001');
    expect(session.name, 'Toan');
    expect(session.accessToken, 'access-1');
    expect(await storage.readAccessToken(), 'access-1');
  });

  test(
    'login sai mật khẩu ném UnauthorizedException với message backend',
    () async {
      await expectLater(
        repository.login(email: 'toan@syna.dev', password: 'wrong'),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            'Sai email hoặc mật khẩu',
          ),
        ),
      );
    },
  );

  test(
    'restoreSession với access token hợp lệ và thông tin session đã lưu',
    () async {
      await storage.saveUserSession(
        accessToken: 'access-saved',
        refreshToken: 'refresh-saved',
        userId: 'u-0000-0001',
        email: 'toan@syna.dev',
        name: 'Toan',
      );

      final session = await repository.restoreSession();

      expect(session, isNotNull);
      expect(session!.email, 'toan@syna.dev');
      expect(session.accessToken, 'access-saved');
      expect(session.userId, 'u-0000-0001');
    },
  );

  test('restoreSession không có token trả null', () async {
    expect(await repository.restoreSession(), isNull);
  });

  test(
    'refreshToken không có refresh token ném UnauthorizedException',
    () async {
      await expectLater(
        repository.refreshToken(),
        throwsA(isA<UnauthorizedException>()),
      );
    },
  );

  test('logout luôn xoá token và session cục bộ', () async {
    await storage.saveUserSession(
      accessToken: 'access-1',
      refreshToken: 'r',
      userId: 'u1',
      email: 'e',
      name: 'n',
    );
    await repository.logout();
    expect(await storage.readAccessToken(), isNull);
    final userSession = await storage.readUserSession();
    expect(userSession.userId, isNull);
  });
}
