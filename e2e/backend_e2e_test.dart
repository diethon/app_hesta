// E2E verify Phase 3 — chạy vào BACKEND THẬT (gateway :8080, WS :8082).
//
// Yêu cầu backend đang chạy (docker compose infra + 6 service).
// Chạy riêng, KHÔNG nằm trong `flutter test` mặc định:
//   flutter test e2e/backend_e2e_test.dart
//
// localhost ở đây là chủ đích: test chạy trên máy host, không phải emulator.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:syna/core/exceptions/app_exception.dart';
import 'package:syna/core/network/network_client.dart';
import 'package:syna/core/services/websocket_service.dart';
import 'package:syna/features/authentication/data/api_auth_repository.dart';
import 'package:syna/features/devices/data/api_device_repository.dart';
import 'package:syna/features/devices/domain/device.dart';
import 'package:syna/features/rooms/data/room_providers.dart';

import '../test/support/in_memory_token_storage.dart';

const apiBaseUrl = String.fromEnvironment(
  'E2E_API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);
const wsUrl = String.fromEnvironment(
  'E2E_WS_URL',
  defaultValue: 'ws://localhost:8082/ws',
);
const demoEmail = 'test@gmail.com';
const demoPassword = '123123123';

Dio _newDio() => Dio(
  BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  ),
);

void main() {
  late InMemoryTokenStorage storage;
  late ApiAuthRepository authRepository;
  late NetworkClient client;
  late ApiDeviceRepository deviceRepository;
  final logger = Logger(level: Level.off);

  setUp(() {
    storage = InMemoryTokenStorage();
    authRepository = ApiAuthRepository(dio: _newDio(), tokenStorage: storage);
    client = NetworkClient(
      baseUrl: apiBaseUrl,
      enableLogs: false,
      tokenStorage: storage,
      authRepository: authRepository,
      logger: logger,
    );
    deviceRepository = ApiDeviceRepository(client);
  });

  test('E2E-1 login user demo qua gateway', () async {
    final session = await authRepository.login(
      email: demoEmail,
      password: demoPassword,
    );

    expect(session.userId, '00000000-0000-0000-0000-000000000001');
    expect(session.email, demoEmail);
    expect(session.accessToken, isNotEmpty);
    expect(session.refreshToken, isNotEmpty);
    expect(await storage.readAccessToken(), session.accessToken);
  });

  test(
    'E2E-2 login sai mật khẩu → UnauthorizedException từ error.code',
    () async {
      await expectLater(
        authRepository.login(email: demoEmail, password: 'wrong-password'),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            isNotEmpty,
          ),
        ),
      );
    },
  );

  test('E2E-3 restoreSession với token đã lưu → GET /me', () async {
    await authRepository.login(email: demoEmail, password: demoPassword);

    final session = await authRepository.restoreSession();

    expect(session, isNotNull);
    expect(session!.userId, '00000000-0000-0000-0000-000000000001');
    expect(session.email, demoEmail);
  });

  test('E2E-4 getDevices trả về seed data đúng model', () async {
    await authRepository.login(email: demoEmail, password: demoPassword);

    final devices = await deviceRepository.getDevices();

    expect(devices.length, greaterThanOrEqualTo(6));
    final lamp = devices.firstWhere((d) => d.name == 'Living Room Lamp');
    expect(lamp.type, DeviceType.light);
    expect(lamp.status, DeviceStatus.online);
    expect(lamp.roomId, isNotEmpty);

    final byId = await deviceRepository.getDeviceById(lamp.id);
    expect(byId.name, lamp.name);
  });

  test(
    'E2E-5 command đổi trạng thái + nhận realtime qua STOMP WebSocket',
    () async {
      await authRepository.login(email: demoEmail, password: demoPassword);
      final devices = await deviceRepository.getDevices();
      final lamp = devices.firstWhere((d) => d.name == 'Living Room Lamp');
      final targetOn = !lamp.isOn;

      final webSocketService = WebSocketService(url: wsUrl, logger: logger);
      addTearDown(webSocketService.dispose);
      final firstEvent = webSocketService
          .subscribeJson('/topic/devices/${lamp.id}/state')
          .first
          .timeout(const Duration(seconds: 15));
      // Chờ CONNECT + SUBSCRIBE hoàn tất trước khi bắn command.
      await Future<void>.delayed(const Duration(seconds: 2));

      final updated = await deviceRepository.updateDeviceState(
        lamp.id,
        DeviceCommand(isOn: targetOn),
      );
      expect(updated.isOn, targetOn);

      final event = await firstEvent;
      expect(event['id'], lamp.id);
      expect(event['isOn'], targetOn);

      // Trả thiết bị về trạng thái ban đầu.
      final restored = await deviceRepository.updateDeviceState(
        lamp.id,
        DeviceCommand(isOn: lamp.isOn),
      );
      expect(restored.isOn, lamp.isOn);
    },
  );

  test(
    'E2E-6 access token hỏng → 401 → tự refresh → retry thành công',
    () async {
      final session = await authRepository.login(
        email: demoEmail,
        password: demoPassword,
      );
      // Giả lập access token hết hạn/hỏng, giữ refresh token thật.
      await storage.saveTokens(
        accessToken: 'broken-access-token',
        refreshToken: session.refreshToken,
      );

      final devices = await deviceRepository.getDevices();

      expect(devices, isNotEmpty);
      final newAccessToken = await storage.readAccessToken();
      expect(newAccessToken, isNotNull);
      expect(newAccessToken, isNot('broken-access-token'));
    },
  );

  test(
    'E2E-7 register user mới → dùng được API → deleteAccount dọn dẹp',
    () async {
      final email = 'e2e-${DateTime.now().millisecondsSinceEpoch}@syna.local';
      final session = await authRepository.register(
        name: 'E2E Bot',
        email: email,
        password: 'e2e-secret-123',
      );
      expect(session.email, email);
      expect(session.accessToken, isNotEmpty);

      // Đăng ký trùng email → ValidationException (EMAIL_ALREADY_EXISTS).
      await expectLater(
        ApiAuthRepository(
          dio: _newDio(),
          tokenStorage: InMemoryTokenStorage(),
        ).register(name: 'E2E Bot', email: email, password: 'e2e-secret-123'),
        throwsA(isA<ValidationException>()),
      );

      // User mới chưa có home → danh sách thiết bị rỗng nhưng gọi được.
      final devices = await deviceRepository.getDevices();
      expect(devices, isEmpty);

      await authRepository.deleteAccount();
      expect(await storage.readAccessToken(), isNull);

      // Login lại bằng tài khoản đã xoá phải thất bại.
      await expectLater(
        authRepository.login(email: email, password: 'e2e-secret-123'),
        throwsA(isA<AppException>()),
      );
    },
  );

  test('E2E-9 remoteRoomsProvider lấy phòng thật, slug khớp visuals', () async {
    await authRepository.login(email: demoEmail, password: demoPassword);
    final container = ProviderContainer(
      overrides: [cloudApiClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);

    final rooms = await container.read(remoteRoomsProvider.future);

    expect(rooms.length, greaterThanOrEqualTo(3));
    final livingRoom = rooms.firstWhere((r) => r.name == 'Living Room');
    expect(livingRoom.id, isNotEmpty); // UUID backend
    expect(livingRoom.slug, 'living-room'); // khoá tra ảnh/config
    expect(livingRoom.deviceCount, greaterThanOrEqualTo(1));

    // Thiết bị seed phải trỏ về đúng UUID phòng → room detail lọc được.
    final devices = await deviceRepository.getDevices();
    expect(devices.where((d) => d.roomId == livingRoom.id), isNotEmpty);
  });

  test('E2E-8 logout xoá phiên cục bộ', () async {
    await authRepository.login(email: demoEmail, password: demoPassword);
    await authRepository.logout();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(await authRepository.restoreSession(), isNull);
  });
}
