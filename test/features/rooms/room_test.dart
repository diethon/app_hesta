import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/devices/presentation/device_visuals.dart';
import 'package:syna/features/rooms/domain/room.dart';

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

    test('roomCardImage và roomBackground trả về asset ảnh cho phòng tiếng Việt', () {
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
    });
  });
}

