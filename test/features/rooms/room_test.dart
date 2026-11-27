import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:syna/core/network/network_client.dart';
import 'package:syna/features/authentication/data/mock_auth_repository.dart';
import 'package:syna/features/devices/presentation/device_visuals.dart';
import 'package:syna/features/rooms/data/room_repository.dart';
import 'package:syna/features/rooms/domain/room.dart';

import '../../support/in_memory_token_storage.dart';

void main() {
  test('Room.slug suy từ tên phòng để tra visuals', () {
    Room room(String name) => Room(
      id: 'uuid-x',
      name: name,
      deviceCount: 0,
      activeCount: 0,
      temperature: 22,
    );

    expect(room('Living Room').slug, 'living-room');
    expect(room('Bedroom').slug, 'bedroom');
    expect(room('  Master   Bedroom ').slug, 'master-bedroom');
  });

  group('DeviceVisuals.canonicalRoomType', () {
    test('chuẩn hoá tên phòng tiếng Việt và tiếng Anh chính xác', () {
      // Phòng khách
      expect(DeviceVisuals.canonicalRoomType('Phòng khách'), 'living-room');
      expect(DeviceVisuals.canonicalRoomType('phòng-khách'), 'living-room');
      expect(DeviceVisuals.canonicalRoomType('Living Room'), 'living-room');

      // Phòng ngủ
      expect(DeviceVisuals.canonicalRoomType('Phòng ngủ'), 'bedroom');
      expect(DeviceVisuals.canonicalRoomType('phòng-ngủ'), 'bedroom');
      expect(DeviceVisuals.canonicalRoomType('Bedroom'), 'bedroom');
      expect(DeviceVisuals.canonicalRoomType('Phòng ngủ master'), 'bedroom');

      // Phòng bếp
      expect(DeviceVisuals.canonicalRoomType('Phòng bếp'), 'kitchen');
      expect(DeviceVisuals.canonicalRoomType('Nhà bếp'), 'kitchen');
      expect(DeviceVisuals.canonicalRoomType('Bếp'), 'kitchen');
      expect(DeviceVisuals.canonicalRoomType('phòng-bếp'), 'kitchen');
      expect(DeviceVisuals.canonicalRoomType('Kitchen'), 'kitchen');

      // Garage
      expect(DeviceVisuals.canonicalRoomType('Garage'), 'garage');
      expect(DeviceVisuals.canonicalRoomType('Nhà xe'), 'garage');
      expect(DeviceVisuals.canonicalRoomType('Gara'), 'garage');

      // Garden
      expect(DeviceVisuals.canonicalRoomType('Garden'), 'garden');
      expect(DeviceVisuals.canonicalRoomType('Sân vườn'), 'garden');
      expect(DeviceVisuals.canonicalRoomType('Vườn'), 'garden');

      // Bathroom
      expect(DeviceVisuals.canonicalRoomType('Phòng tắm'), 'bathroom');
      expect(DeviceVisuals.canonicalRoomType('Nhà vệ sinh'), 'bathroom');
      expect(DeviceVisuals.canonicalRoomType('Bathroom'), 'bathroom');
    });

    test(
      'roomCardImage và roomBackground trả về asset ảnh cho phòng tiếng Việt',
      () {
        expect(
          DeviceVisuals.roomCardImage('Phòng khách'),
          'assets/images/rooms/horizontal_room/livingroom.jpg',
        );
        expect(
          DeviceVisuals.roomCardImage('Phòng ngủ'),
          'assets/images/rooms/horizontal_room/bedroom.jpg',
        );
        expect(
          DeviceVisuals.roomCardImage('Phòng bếp'),
          'assets/images/rooms/horizontal_room/kitchen.jpg',
        );
        expect(
          DeviceVisuals.roomCardImage('Garage'),
          'assets/images/rooms/horizontal_room/garage.jpg',
        );
        expect(
          DeviceVisuals.roomCardImage('Garden'),
          'assets/images/rooms/horizontal_room/garden.jpg',
        );

        expect(
          DeviceVisuals.roomBackground('Phòng khách'),
          'assets/images/rooms/vertical_room/livingroom.png',
        );
        expect(
          DeviceVisuals.roomBackground('Phòng ngủ'),
          'assets/images/rooms/vertical_room/bedroom.jpg',
        );
        expect(
          DeviceVisuals.roomBackground('Phòng bếp'),
          'assets/images/rooms/vertical_room/kitchen.jpg',
        );
      },
    );
  });

  group('RoomRepository CRUD & Batch Control', () {
    test('MockRoomRepository thực hiện create, update, delete và sendRoomCommand', () async {
      final repo = MockRoomRepository();
      final initialCount = repo.currentRooms.length;

      final created = await repo.createRoom(
        homeId: 'home-1',
        name: 'Phòng Làm Việc',
      );
      expect(created.name, 'Phòng Làm Việc');
      expect(repo.currentRooms.length, initialCount + 1);

      final updated = await repo.updateRoom(
        homeId: 'home-1',
        roomId: created.id,
        name: 'Phòng Đọc Sách',
      );
      expect(updated.name, 'Phòng Đọc Sách');

      final batch = await repo.sendRoomCommand(
        roomId: created.id,
        action: 'TURN_ON',
      );
      expect(batch.isSuccess, isTrue);

      await repo.deleteRoom(homeId: 'home-1', roomId: created.id);
      expect(repo.currentRooms.length, initialCount);
    });

    test('ApiRoomRepository gọi đúng endpoint CRUD & batch room command', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      String? lastMethod;
      String? lastPath;
      server.listen((request) async {
        lastMethod = request.method;
        lastPath = request.uri.path;
        Object body;
        if (lastMethod == 'POST' && lastPath!.endsWith('/rooms')) {
          body = {
            'code': 1000,
            'result': {'id': 'room-99', 'name': 'Phòng Họp'},
          };
        } else if (lastMethod == 'PUT') {
          body = {
            'code': 1000,
            'result': {'id': 'room-99', 'name': 'Phòng Mới'},
          };
        } else if (lastMethod == 'POST' && lastPath!.endsWith('/command')) {
          body = {
            'code': 1000,
            'result': [
              {'deviceId': 'd1', 'status': 'SUCCESS'},
              {'deviceId': 'd2', 'status': 'FAILED'},
            ],
          };
        } else {
          body = {'code': 1000, 'message': 'Deleted'};
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
      final repo = ApiRoomRepository(client);

      final created = await repo.createRoom(homeId: 'h1', name: 'Phòng Họp');
      expect(created.id, 'room-99');
      expect(lastMethod, 'POST');
      expect(lastPath, '/api/v1/homes/h1/rooms');

      final updated = await repo.updateRoom(
        homeId: 'h1',
        roomId: 'room-99',
        name: 'Phòng Mới',
      );
      expect(updated.name, 'Phòng Mới');
      expect(lastMethod, 'PUT');
      expect(lastPath, '/api/v1/homes/h1/rooms/room-99');

      final batch = await repo.sendRoomCommand(
        roomId: 'room-99',
        action: 'TURN_OFF',
      );
      expect(batch.totalDevices, 2);
      expect(batch.successCount, 1);
      expect(batch.failureCount, 1);

      await repo.deleteRoom(homeId: 'h1', roomId: 'room-99');
      expect(lastMethod, 'DELETE');
      expect(lastPath, '/api/v1/homes/h1/rooms/room-99');
    });
  });
}
