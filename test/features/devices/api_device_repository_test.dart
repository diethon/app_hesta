import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:syna/core/network/network_client.dart';
import 'package:syna/features/authentication/data/mock_auth_repository.dart';
import 'package:syna/features/devices/data/api_device_repository.dart';
import 'package:syna/features/devices/data/models/device_dto.dart';
import 'package:syna/features/devices/domain/device.dart';

import '../../support/in_memory_token_storage.dart';

const _deviceHestaJson = {
  'id': 'd8e5b6a0-0000-0000-0000-000000000001',
  'name': 'Ceiling Light',
  'roomId': 'a1b2c3d4-0000-0000-0000-000000000001',
  'deviceType': 'LIGHT',
  'status': 'ONLINE',
  'currentState': {
    'power': true,
    'brightness': 80,
  },
  'isFavorite': true,
};

void main() {
  late HttpServer server;
  late ApiDeviceRepository repository;
  Map<String, dynamic>? lastCommandBody;

  setUp(() async {
    lastCommandBody = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      Object body;
      if (request.method == 'GET' && (path == '/api/v1/devices' || path.endsWith('/devices'))) {
        body = {
          'code': 1000,
          'message': 'Success',
          'result': [_deviceHestaJson],
        };
      } else if (request.method == 'POST' && path.endsWith('/command')) {
        lastCommandBody =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        body = {
          'code': 1000,
          'message': 'Success',
          'result': {
            'commandId': 'cmd-1',
            'deviceId': 'd8e5b6a0-0000-0000-0000-000000000001',
            'action': lastCommandBody?['action'] ?? 'POWER_OFF',
            'status': 'SUCCESS',
          },
        };
      } else {
        final dev = Map<String, dynamic>.from(_deviceHestaJson);
        if (lastCommandBody != null && lastCommandBody!['action'] == 'POWER_OFF') {
          dev['currentState'] = {'power': false, 'brightness': 80};
        }
        body = {'code': 1000, 'message': 'Success', 'result': dev};
      }
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await request.response.close();
    });

    final storage = InMemoryTokenStorage();
    final client = NetworkClient(
      baseUrl: 'http://${server.address.address}:${server.port}',
      enableLogs: false,
      tokenStorage: storage,
      authRepository: MockAuthRepository(storage),
      logger: Logger(level: Level.off),
    );
    repository = ApiDeviceRepository(
      client,
      getHomeId: () => 'h-0001',
    );
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('getDevices parse envelope + DTO sang domain', () async {
    final devices = await repository.getDevices();

    expect(devices, hasLength(1));
    final device = devices.single;
    expect(device.id, _deviceHestaJson['id']);
    expect(device.type, DeviceType.light);
    expect(device.status, DeviceStatus.online);
    expect(device.isOn, isTrue);
    expect(device.brightness, 80);
    expect(device.isFavorite, isTrue);
  });

  test('getDeviceById trả về đúng device', () async {
    final device = await repository.getDeviceById(_deviceHestaJson['id']! as String);
    expect(device.name, 'Ceiling Light');
  });

  test('updateDeviceState gửi đúng body command và nhận state mới', () async {
    final device = await repository.updateDeviceState(
      _deviceHestaJson['id']! as String,
      const DeviceCommand(isOn: false),
    );

    expect(device.isOn, isFalse);
    expect(lastCommandBody, {
      'action': 'POWER_OFF',
      'parameters': <String, dynamic>{'power': false},
    });
  });

  group('deviceCommandToRequestBody', () {
    test('một field đơn lẻ dùng action chuyên biệt', () {
      expect(deviceCommandToRequestBody(const DeviceCommand(isOn: true)), {
        'action': 'POWER_ON',
        'parameters': <String, dynamic>{'power': true},
      });
      expect(deviceCommandToRequestBody(const DeviceCommand(brightness: 60)), {
        'action': 'SET_BRIGHTNESS',
        'parameters': {'brightness': 60},
      });
      expect(deviceCommandToRequestBody(const DeviceCommand(temperature: 22)), {
        'action': 'SET_TEMPERATURE',
        'parameters': {'temperature': 22},
      });
    });

    test('nhiều field kết hợp ưu tiên action tương ứng', () {
      expect(
        deviceCommandToRequestBody(
          const DeviceCommand(isOn: true, brightness: 40),
        ),
        {
          'action': 'SET_BRIGHTNESS',
          'parameters': {'brightness': 40, 'power': true},
        },
      );
    });
  });
}
