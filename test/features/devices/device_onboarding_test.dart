import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:syna/core/network/network_client.dart';
import 'package:syna/features/authentication/data/mock_auth_repository.dart';
import 'package:syna/features/devices/data/ble_provisioning_service.dart';
import 'package:syna/features/devices/data/device_onboarding_repository.dart';
import 'package:syna/features/devices/domain/device_onboarding_models.dart';
import 'package:syna/features/devices/presentation/onboarding_controller.dart';

import '../../support/in_memory_token_storage.dart';

void main() {
  late HttpServer server;
  late NetworkClient networkClient;
  late ApiDeviceOnboardingRepository onboardingRepo;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      if (request.method == 'GET' && path.startsWith('/api/v1/devices/qr/')) {
        final token = path.replaceFirst('/api/v1/devices/qr/', '');
        if (token == 'valid-test-token') {
          final body = {
            'code': 1000,
            'message': 'Success',
            'result': {
              'deviceId': 'dev-123',
              'name': 'Living Light',
              'deviceType': 'LIGHT',
              'model': 'SYNA-RGB-001',
              'serialNumber': 'SYNA-001-0001',
              'status': 'UNCLAIMED',
            },
          };
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(body));
        } else {
          final body = {
            'code': 1042,
            'message': 'QR token is invalid or does not exist',
          };
          request.response
            ..statusCode = 400
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(body));
        }
      } else if (request.method == 'POST' && path.endsWith('/claim')) {
        final body = {
          'code': 1000,
          'message': 'Device claimed successfully',
          'result': {
            'id': 'dev-123',
            'name': 'Living Room Light',
            'roomId': 'room-001',
            'deviceType': 'LIGHT',
            'status': 'ONLINE',
            'currentState': {'power': true},
          },
        };
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(body));
      } else {
        request.response
          ..statusCode = 404
          ..write('Not found');
      }
      await request.response.close();
    });

    final storage = InMemoryTokenStorage();
    networkClient = NetworkClient(
      baseUrl: 'http://${server.address.address}:${server.port}',
      enableLogs: false,
      tokenStorage: storage,
      authRepository: MockAuthRepository(storage),
      logger: Logger(level: Level.off),
    );
    onboardingRepo = ApiDeviceOnboardingRepository(networkClient);
  });

  tearDown(() async {
    await server.close(force: true);
  });

  group('DeviceOnboardingRepository Tests', () {
    test('resolveQrToken returns DevicePreview for valid token', () async {
      final preview = await onboardingRepo.resolveQrToken('valid-test-token');
      expect(preview.deviceId, 'dev-123');
      expect(preview.name, 'Living Light');
      expect(preview.deviceType, 'LIGHT');
      expect(preview.model, 'SYNA-RGB-001');
      expect(preview.serialNumber, 'SYNA-001-0001');
      expect(preview.status, 'UNCLAIMED');
    });

    test('resolveQrToken throws exception on invalid token', () async {
      expect(
        () => onboardingRepo.resolveQrToken('invalid-token'),
        throwsException,
      );
    });

    test('claimDevice returns claimed device data', () async {
      final claimed = await onboardingRepo.claimDevice(
        deviceId: 'dev-123',
        token: 'valid-test-token',
        homeId: 'home-001',
        roomId: 'room-001',
        name: 'Living Room Light',
        nodeCode: 'esp32-001',
      );
      expect(claimed.id, 'dev-123');
      expect(claimed.name, 'Living Room Light');
      expect(claimed.status.name, 'online');
    });
  });

  group('BleProvisioningService Tests', () {
    final bleService = SimBleProvisioningService();

    test('scanForDevices finds SYNA-ESP32S3 device', () async {
      final devices = await bleService.scanForDevices(
        timeout: const Duration(milliseconds: 50),
      );
      expect(devices, isNotEmpty);
      expect(devices.first.name, 'SYNA-ESP32S3');
    });

    test('provisionWifi executes with wifi and mqtt callbacks successfully', () async {
      bool wifiCalled = false;
      bool mqttCalled = false;
      await bleService.provisionWifi(
        ssid: 'Home_WiFi',
        password: 'SecretPassword',
        onWifiConnected: () => wifiCalled = true,
        onMqttConnected: () => mqttCalled = true,
      );
      expect(wifiCalled, isTrue);
      expect(mqttCalled, isTrue);
    });
  });

  group('OnboardingController State Machine Tests', () {
    test('full onboarding flow succeeds step-by-step', () async {
      final bleService = SimBleProvisioningService();
      final container = ProviderContainer(
        overrides: [
          deviceOnboardingRepositoryProvider.overrideWithValue(onboardingRepo),
          bleProvisioningServiceProvider.overrideWithValue(bleService),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(onboardingControllerProvider, (_, __) {});
      final notifier = container.read(onboardingControllerProvider.notifier);

      // 1. Initial State
      expect(container.read(onboardingControllerProvider).step, OnboardingStep.scanQr);

      // 2. Scan QR
      await notifier.onQrScanned('syna://device/register?token=valid-test-token');
      var state = container.read(onboardingControllerProvider);
      expect(state.step, OnboardingStep.verifyDevice);
      expect(state.preview?.deviceId, 'dev-123');
      expect(state.token, 'valid-test-token');

      // 3. Confirm Device -> starts BLE scanning
      await notifier.confirmDevice();
      state = container.read(onboardingControllerProvider);
      expect(state.selectedBleDevice?.name, 'SYNA-ESP32S3');

      // 4. Connect BLE Candidate
      await notifier.connectBleDevice(state.selectedBleDevice!);
      state = container.read(onboardingControllerProvider);
      expect(state.step, OnboardingStep.wifiProvisioning);
      expect(state.selectedBleDevice?.name, 'SYNA-ESP32S3');

      // 5. Submit Wi-Fi credentials -> connects Wi-Fi & MQTT
      await notifier.submitWifiCredentials('Home_WiFi', 'Password123');
      state = container.read(onboardingControllerProvider);
      expect(state.step, OnboardingStep.homeRoomSelection);
      expect(state.wifiSsid, 'Home_WiFi');
      expect(state.wifiConnected, isTrue);
      expect(state.mqttConnected, isTrue);

      // 6. Select Home & Room & Name
      notifier.updateSelectedHomeAndRoom(
        homeId: 'home-001',
        roomId: 'room-001',
        customName: 'Living Room Light',
      );

      // 7. Claim Device
      await notifier.claimDevice();
      state = container.read(onboardingControllerProvider);
      expect(state.step, OnboardingStep.completed);

      // 8. Reset
      notifier.reset();
      expect(container.read(onboardingControllerProvider).step, OnboardingStep.scanQr);
      subscription.close();
    });

    test('invalid QR code sets error state', () async {
      final bleService = SimBleProvisioningService();
      final container = ProviderContainer(
        overrides: [
          deviceOnboardingRepositoryProvider.overrideWithValue(onboardingRepo),
          bleProvisioningServiceProvider.overrideWithValue(bleService),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(onboardingControllerProvider, (_, __) {});
      final notifier = container.read(onboardingControllerProvider.notifier);
      await notifier.onQrScanned('syna://device/register?token=invalid-token');

      final state = container.read(onboardingControllerProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.step, OnboardingStep.error);
      subscription.close();
    });
  });
}
