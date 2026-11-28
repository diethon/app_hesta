import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../devices/data/device_providers.dart';
import '../../devices/domain/device.dart';
import '../../home/data/home_providers.dart';
import '../domain/room.dart';
import 'room_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  if (kUseMockData) {
    return MockRoomRepository();
  }
  return ApiRoomRepository(ref.watch(cloudApiClientProvider));
});

/// Danh sách phòng theo `homeId` cụ thể (FutureProvider.family)
final roomsForHomeProvider = FutureProvider.family
    .autoDispose<List<Room>, String>((ref, homeId) async {
      if (homeId.isEmpty) {
        return const <Room>[];
      }

      if (kUseMockData) {
        final devices = ref.watch(devicesControllerProvider).valueOrNull ?? [];
        final repo = ref.watch(roomRepositoryProvider);
        final baseRooms = repo is MockRoomRepository
            ? repo.currentRooms
            : const <Room>[];
        return [
          for (final room in baseRooms)
            _mockRoom(room.id, room.name, room.temperature, devices),
        ];
      }

      final client = ref.watch(cloudApiClientProvider);
      try {
        final response = await client.get<dynamic>(
          '/api/v1/homes/$homeId/rooms',
        );
        final body = response.data;
        final data = body is Map
            ? (body['result'] ?? body['data'])
            : (body is List ? body : null);
        if (data is! List) {
          return const <Room>[];
        }
        return data
            .whereType<Map>()
            .map(
              (json) => Room(
                id: (json['id'] ?? '').toString(),
                name: (json['name'] ?? '').toString(),
                deviceCount: (json['deviceCount'] as num?)?.toInt() ?? 0,
                activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
                temperature: (json['temperature'] as num?)?.toInt() ?? 22,
                floor: (json['floor'] as num?)?.toInt(),
              ),
            )
            .toList();
      } catch (_) {
        return const <Room>[];
      }
    });

/// Danh sách phòng thật từ backend_hesta `GET /api/v1/homes/{homeId}/rooms`
/// ({id, name}). autoDispose để refetch khi quay lại màn hình.
final remoteRoomsProvider = FutureProvider.autoDispose<List<Room>>((ref) async {
  final homeId = ref.watch(currentHomeIdProvider);
  if (homeId == null) {
    return const <Room>[];
  }

  return ref.watch(roomsForHomeProvider(homeId).future);
});

final roomsProvider = Provider.autoDispose<List<Room>>((ref) {
  final devices = ref.watch(devicesControllerProvider).valueOrNull ?? [];

  if (kUseMockData) {
    final repo = ref.watch(roomRepositoryProvider);
    final baseRooms = repo is MockRoomRepository
        ? repo.currentRooms
        : const <Room>[];
    return [
      for (final room in baseRooms)
        _mockRoom(room.id, room.name, room.temperature, devices),
    ];
  }

  final remote = ref.watch(remoteRoomsProvider).valueOrNull ?? const <Room>[];
  // Đếm lại device/active từ devicesController để số liệu bám theo
  // realtime update, không phụ thuộc snapshot lúc fetch rooms.
  return [
    for (final room in remote)
      Room(
        id: room.id,
        name: room.name,
        deviceCount: devices.where((d) => d.roomId == room.id).length,
        activeCount: devices.where((d) => d.roomId == room.id && d.isOn).length,
        temperature: room.temperature,
        floor: room.floor,
      ),
  ];
});

Room _mockRoom(String id, String name, int temperature, List<Device> devices) {
  final inRoom = devices.where((device) => device.roomId == id).toList();
  return Room(
    id: id,
    name: name,
    deviceCount: inRoom.length,
    activeCount: inRoom.where((device) => device.isOn).length,
    temperature: temperature,
  );
}
