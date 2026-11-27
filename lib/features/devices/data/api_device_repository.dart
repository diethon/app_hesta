import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exception.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/network/network_client.dart';
import '../domain/device.dart';
import '../domain/device_repository.dart';
import 'mock_device_repository.dart';
import 'models/device_dto.dart';

/// Repository giao tiếp với backend_hesta (:8080).
/// Đi qua NetworkClient có sẵn Bearer Token.
class ApiDeviceRepository implements DeviceRepository {
  ApiDeviceRepository(this._client, {String? Function()? getHomeId})
    : _getHomeId = getHomeId;

  final NetworkClient _client;
  final String? Function()? _getHomeId;

  @override
  Future<List<Device>> getDevices() async {
    try {
      String? homeId = _getHomeId?.call();
      if (homeId == null) {
        // Lấy homeId từ my-homes nếu chưa có sẵn
        final homesRes = await _client.get<dynamic>('/api/v1/homes/my-homes');
        final rawHomes = homesRes.data;
        final homesBody = rawHomes is Map
            ? (rawHomes['result'] ?? rawHomes['data'])
            : (rawHomes is List ? rawHomes : null);
        if (homesBody is List && homesBody.isNotEmpty) {
          final first = homesBody.first;
          if (first is Map) {
            homeId = (first['homeId'] ?? first['id'])?.toString();
          }
        }
      }

      if (homeId == null) {
        return const <Device>[];
      }

      final response = await _client.get<dynamic>(
        '/api/v1/homes/$homeId/devices',
      );
      final raw = response.data;
      final data = raw is Map
          ? (raw['result'] ?? raw['data'])
          : (raw is List ? raw : null);
      if (data is! List) {
        return const <Device>[];
      }
      return data
          .whereType<Map>()
          .map(
            (json) =>
                DeviceDto.fromJson(Map<String, dynamic>.from(json)).toDomain(),
          )
          .toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Device> getDeviceById(String id) async {
    try {
      final response = await _client.get<dynamic>('/api/v1/devices/$id');
      return _deviceFrom(response);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Device> updateDeviceState(String id, DeviceCommand command) async {
    try {
      final endpoint = command.isAc
          ? '/api/v1/devices/$id/air-conditioner/command'
          : '/api/v1/devices/$id/command';

      final response = await _client.post<Map<String, dynamic>>(
        endpoint,
        data: deviceCommandToRequestBody(command),
      );

      final body = response.data;
      final code = body?['code'];
      if (code != null && code != 1000) {
        throw ValidationException(
          body?['message'] as String? ?? 'Gửi lệnh thất bại.',
        );
      }

      // backend_hesta trả về ApiResponse<CommandResult>.
      // Lấy trạng thái mới nhất từ server qua getDeviceById:
      try {
        return await getDeviceById(id);
      } catch (_) {
        final result = body?['result'];
        final ackState = result is Map<String, dynamic>
            ? result['acknowledgedState']
            : null;
        if (ackState is Map<String, dynamic>) {
          return DeviceDto.fromJson({
            'id': id,
            'name': 'Device',
            'currentState': ackState,
          }).toDomain();
        }
        throw const UnknownException(
          'Không thể cập nhật trạng thái thiết bị sau khi điều khiển.',
        );
      }
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Device> updateDeviceConfig(
    String id, {
    String? name,
    String? roomId,
    String? icon,
    double? wattage,
  }) async {
    final payload = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
      if (icon != null && icon.trim().isNotEmpty) 'icon': icon.trim(),
      if (wattage != null) 'settings': {'wattage': wattage.toInt()},
    };
    try {
      final response = await _client.put<dynamic>(
        '/api/v1/devices/$id',
        data: payload,
      );
      final updated = _deviceFrom(response);
      return wattage != null ? updated.copyWith(energyWatts: wattage) : updated;
    } on DioException catch (error) {
      if (error.response != null) {
        throw mapDioException(error);
      }
      try {
        return await MockDeviceRepository().updateDeviceConfig(
          id,
          name: name,
          roomId: roomId,
          icon: icon,
          wattage: wattage,
        );
      } catch (_) {
        throw mapDioException(error);
      }
    }
  }

  @override
  Future<void> removeDevice(String id) async {
    try {
      await _client.dio.delete<dynamic>('/api/v1/devices/$id');
    } on DioException catch (error) {
      if (error.response != null) {
        throw mapDioException(error);
      }
      try {
        await MockDeviceRepository().removeDevice(id);
      } catch (_) {
        throw mapDioException(error);
      }
    }
  }

  @override
  Future<Device> cancelDeviceAutomation(String id, {int minutes = 30}) async {
    try {
      final response = await _client.post<dynamic>(
        '/api/v1/devices/$id/automation/cancel',
        data: {'minutes': minutes},
      );
      final raw = response.data;
      final until = raw is Map
          ? (raw['result'] ?? raw['data'])?.toString()
          : null;
      final current = await getDeviceById(id);
      return current.copyWith(
        manualOverrideUntil:
            until ??
            DateTime.now().add(Duration(minutes: minutes)).toIso8601String(),
        manualOverrideActive: true,
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Device> extendDeviceAutomation(String id, {int minutes = 60}) async {
    try {
      final response = await _client.post<dynamic>(
        '/api/v1/devices/$id/automation/extend',
        data: {'minutes': minutes},
      );
      final raw = response.data;
      final until = raw is Map
          ? (raw['result'] ?? raw['data'])?.toString()
          : null;
      final current = await getDeviceById(id);
      return current.copyWith(
        manualOverrideUntil:
            until ??
            DateTime.now().add(Duration(minutes: minutes)).toIso8601String(),
        manualOverrideActive: true,
      );
    } on DioException catch (error) {
      if (error.response != null) {
        throw mapDioException(error);
      }
      try {
        return await MockDeviceRepository().extendDeviceAutomation(
          id,
          minutes: minutes,
        );
      } catch (_) {
        throw mapDioException(error);
      }
    }
  }

  @override
  Future<Device> resumeDeviceAutomation(String id) async {
    try {
      await _client.post<dynamic>('/api/v1/devices/$id/automation/resume');
      final current = await getDeviceById(id);
      return current.copyWith(
        manualOverrideUntil: '',
        manualOverrideActive: false,
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDeviceOverrideHistory(String id) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/v1/devices/$id/automation/overrides',
      );
      final raw = response.data;
      final data = raw is Map ? (raw['result'] ?? raw['data']) : null;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      if (error.response != null) {
        throw mapDioException(error);
      }
      return MockDeviceRepository().getDeviceOverrideHistory(id);
    } catch (_) {
      return MockDeviceRepository().getDeviceOverrideHistory(id);
    }
  }

  @override
  Future<Device> getDeviceHealth(String id) async {
    try {
      final response = await _client.get<dynamic>('/api/v1/devices/$id/health');
      final raw = response.data;
      final data = raw is Map ? (raw['result'] ?? raw['data']) : null;
      final current = await getDeviceById(id);
      if (data is Map) {
        return current.copyWith(
          switchCycles: (data['switchCycles'] as num?)?.toInt(),
          maxRatedCycles: (data['maxRatedCycles'] as num?)?.toInt() ?? 100000,
          healthPercent: (data['healthPercent'] as num?)?.toDouble() ?? 99.0,
          chatteringWarning: data['chatteringWarning'] == true,
          safetyTripped: data['safetyTripped'] == true,
        );
      }
      return current;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<DeviceUptimeInfo> getDeviceUptime(String id, {int days = 7}) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/v1/devices/$id/analytics/uptime',
        queryParameters: {'days': days},
      );
      final raw = response.data;
      final data = raw is Map ? (raw['result'] ?? raw['data']) : null;
      if (data is Map) {
        return DeviceUptimeInfo.fromJson(Map<String, dynamic>.from(data));
      }
      return MockDeviceRepository().getDeviceUptime(id, days: days);
    } on DioException catch (error) {
      if (error.response != null) {
        throw mapDioException(error);
      }
      return MockDeviceRepository().getDeviceUptime(id, days: days);
    } catch (_) {
      return MockDeviceRepository().getDeviceUptime(id, days: days);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDeviceAuditHistory(String id) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/v1/devices/$id/history',
      );
      final raw = response.data;
      final data = raw is Map ? (raw['result'] ?? raw['data']) : null;
      if (data is List && data.isNotEmpty) {
        return data
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      return await MockDeviceRepository().getDeviceAuditHistory(id);
    } catch (_) {
      return MockDeviceRepository().getDeviceAuditHistory(id);
    }
  }

  @override
  Future<String> exportDeviceAuditExcel(String id, String deviceName) async {
    return _exportAuditFile(
      path: '/api/v1/devices/$id/history/export/excel',
      id: id,
      deviceName: deviceName,
      extension: 'xlsx',
      mockFallback: () =>
          MockDeviceRepository().exportDeviceAuditExcel(id, deviceName),
    );
  }

  @override
  Future<String> exportDeviceAuditCsv(String id, String deviceName) async {
    return _exportAuditFile(
      path: '/api/v1/devices/$id/history/export',
      id: id,
      deviceName: deviceName,
      extension: 'csv',
      mockFallback: () =>
          MockDeviceRepository().exportDeviceAuditCsv(id, deviceName),
    );
  }

  Future<String> _exportAuditFile({
    required String path,
    required String id,
    required String deviceName,
    required String extension,
    required Future<String> Function() mockFallback,
  }) async {
    try {
      final response = await _client.dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      final bytes = response.data ?? <int>[];
      final sanitized = deviceName.replaceAll(RegExp(r'\s+'), '_');
      if (bytes.isNotEmpty) {
        try {
          final file = File(
            '/sdcard/Download/lich_su_${sanitized}_$id.$extension',
          );
          await file.writeAsBytes(bytes);
          return file.path;
        } catch (_) {
          return 'lich_su_${sanitized}_$id.$extension (${bytes.length} bytes)';
        }
      }
      return await mockFallback();
    } on DioException catch (error) {
      if (error.response != null) {
        throw mapDioException(error);
      }
      return mockFallback();
    } catch (_) {
      return mockFallback();
    }
  }

  @override
  Future<Device> updateDeviceWattage(String id, double wattage) async {
    return updateDeviceConfig(id, wattage: wattage);
  }

  Device _deviceFrom(Response<dynamic> response) {
    final body = response.data;
    final Map<String, dynamic>? data;
    if (body is Map) {
      final res = body['result'] ?? body['data'];
      if (res is Map) {
        data = Map<String, dynamic>.from(res);
      } else if (body.containsKey('id') || body.containsKey('deviceId')) {
        data = Map<String, dynamic>.from(body);
      } else {
        data = null;
      }
    } else {
      data = null;
    }

    if (data == null) {
      throw const UnknownException('Phản hồi từ máy chủ không hợp lệ.');
    }
    return DeviceDto.fromJson(data).toDomain();
  }
}
