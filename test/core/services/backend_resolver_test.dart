import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:syna/core/network/network_client.dart';
import 'package:syna/core/services/backend_resolver.dart';
import 'package:syna/features/authentication/data/mock_auth_repository.dart';

import '../../support/in_memory_token_storage.dart';

NetworkClient _client(String baseUrl) {
  final storage = InMemoryTokenStorage();
  return NetworkClient(
    baseUrl: baseUrl,
    enableLogs: false,
    tokenStorage: storage,
    authRepository: MockAuthRepository(storage),
    logger: Logger(level: Level.off),
  );
}

void main() {
  test(
    'a reachable backend without /actuator/health (404) is cloud, not offline',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      });
      addTearDown(() => server.close(force: true));
      final client = _client('http://${server.address.address}:${server.port}');

      final mode = await BackendResolver(
        edgeClient: client,
        cloudClient: client,
      ).resolve();

      expect(mode, ConnectionMode.cloud);
    },
  );

  test('no server listening is offline', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true);
    final client = _client('http://127.0.0.1:$port');

    final mode = await BackendResolver(
      edgeClient: client,
      cloudClient: client,
    ).resolve();

    expect(mode, ConnectionMode.offline);
  });
}
