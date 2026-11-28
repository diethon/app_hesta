import 'package:dio/dio.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/network/network_client.dart';
import '../domain/room.dart';

class RoomBatchCommandResult {
  const RoomBatchCommandResult({
    required this.totalDevices,
    required this.successCount,
    required this.failureCount,
  });

  final int totalDevices;
  final int successCount;
  final int failureCount;

  bool get isSuccess => totalDevices == 0 || successCount > 0;
}

abstract interface class RoomRepository {
  Future<Room> createRoom({
    required String homeId,
    required String name,
    String icon = 'default',
  });

  Future<Room> updateRoom({
    required String homeId,
    required String roomId,
    required String name,
    String? icon,
  });

  Future<void> deleteRoom({required String homeId, required String roomId});

  Future<RoomBatchCommandResult> sendRoomCommand({
    required String roomId,
    required String action,
    Map<String, dynamic>? parameters,
  });
}

class ApiRoomRepository implements RoomRepository {
  ApiRoomRepository(this._client);

  final NetworkClient _client;

  @override
  Future<Room> createRoom({
    required String homeId,
    required String name,
    String icon = 'default',
  }) async {
    try {
      final response = await _client.post<dynamic>(
        '/api/v1/homes/$homeId/rooms',
        data: {'name': name.trim(), 'icon': icon},
      );
      return _roomFromResponse(response.data, fallbackName: name.trim());
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Room> updateRoom({
    required String homeId,
    required String roomId,
    required String name,
    String? icon,
  }) async {
    try {
      final response = await _client.put<dynamic>(
        '/api/v1/homes/$homeId/rooms/$roomId',
        data: {
          'name': name.trim(),
          if (icon != null && icon.trim().isNotEmpty) 'icon': icon.trim(),
        },
      );
      return _roomFromResponse(
        response.data,
        fallbackId: roomId,
        fallbackName: name.trim(),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> deleteRoom({
    required String homeId,
    required String roomId,
  }) async {
    try {
      await _client.dio.delete<dynamic>('/api/v1/homes/$homeId/rooms/$roomId');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<RoomBatchCommandResult> sendRoomCommand({
    required String roomId,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _client.post<dynamic>(
        '/api/v1/rooms/$roomId/command',
        data: {
          'action': action,
          'parameters': parameters ?? <String, dynamic>{},
        },
      );
      final raw = response.data;
      final result = raw is Map ? (raw['result'] ?? raw['data']) : raw;
      if (result is List) {
        int success = 0;
        for (final item in result) {
          if (item is Map) {
            final status = item['status']?.toString().toUpperCase();
            final ack = item['acknowledged'] == true;
            if (status == 'SUCCESS' ||
                status == 'SUCCEEDED' ||
                status == 'OK' ||
                ack ||
                (status == null && item['error'] == null)) {
              success++;
            }
          }
        }
        return RoomBatchCommandResult(
          totalDevices: result.length,
          successCount: success,
          failureCount: result.length - success,
        );
      }
      return const RoomBatchCommandResult(
        totalDevices: 0,
        successCount: 0,
        failureCount: 0,
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Room _roomFromResponse(
    dynamic raw, {
    String fallbackId = '',
    required String fallbackName,
  }) {
    final data = raw is Map ? (raw['result'] ?? raw['data'] ?? raw) : null;
    if (data is Map) {
      return Room(
        id: (data['id'] ?? fallbackId).toString(),
        name: (data['name'] ?? fallbackName).toString(),
        deviceCount: (data['deviceCount'] as num?)?.toInt() ?? 0,
        activeCount: (data['activeCount'] as num?)?.toInt() ?? 0,
        temperature: (data['temperature'] as num?)?.toInt() ?? 22,
        floor: (data['floor'] as num?)?.toInt(),
      );
    }
    return Room(
      id: fallbackId,
      name: fallbackName,
      deviceCount: 0,
      activeCount: 0,
      temperature: 22,
    );
  }
}

class MockRoomRepository implements RoomRepository {
  final List<Room> _rooms = [
    const Room(
      id: 'living-room',
      name: 'Phòng khách',
      deviceCount: 0,
      activeCount: 0,
      temperature: 22,
    ),
    const Room(
      id: 'bedroom',
      name: 'Phòng ngủ',
      deviceCount: 0,
      activeCount: 0,
      temperature: 20,
    ),
    const Room(
      id: 'kitchen',
      name: 'Nhà bếp',
      deviceCount: 0,
      activeCount: 0,
      temperature: 24,
    ),
    const Room(
      id: 'garage',
      name: 'Nhà để xe',
      deviceCount: 0,
      activeCount: 0,
      temperature: 18,
    ),
    const Room(
      id: 'bathroom',
      name: 'Phòng tắm',
      deviceCount: 0,
      activeCount: 0,
      temperature: 23,
    ),
    const Room(
      id: 'garden',
      name: 'Sân vườn',
      deviceCount: 0,
      activeCount: 0,
      temperature: 21,
    ),
  ];

  List<Room> get currentRooms => List<Room>.unmodifiable(_rooms);

  @override
  Future<Room> createRoom({
    required String homeId,
    required String name,
    String icon = 'default',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final trimmed = name.trim();
    if (_rooms.any((r) => r.name.toLowerCase() == trimmed.toLowerCase())) {
      throw StateError('Tên phòng "$trimmed" đã tồn tại.');
    }
    final created = Room(
      id: 'room-${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
      deviceCount: 0,
      activeCount: 0,
      temperature: 22,
    );
    _rooms.add(created);
    return created;
  }

  @override
  Future<Room> updateRoom({
    required String homeId,
    required String roomId,
    required String name,
    String? icon,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final trimmed = name.trim();
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) {
      throw StateError('Không tìm thấy phòng.');
    }
    if (_rooms.any(
      (r) => r.id != roomId && r.name.toLowerCase() == trimmed.toLowerCase(),
    )) {
      throw StateError('Tên phòng "$trimmed" đã tồn tại.');
    }
    final old = _rooms[idx];
    final updated = Room(
      id: old.id,
      name: trimmed,
      deviceCount: old.deviceCount,
      activeCount: old.activeCount,
      temperature: old.temperature,
      floor: old.floor,
    );
    _rooms[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteRoom({
    required String homeId,
    required String roomId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _rooms.removeWhere((r) => r.id == roomId);
  }

  @override
  Future<RoomBatchCommandResult> sendRoomCommand({
    required String roomId,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const RoomBatchCommandResult(
      totalDevices: 1,
      successCount: 1,
      failureCount: 0,
    );
  }
}
