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
        final homesRes =
            await _client.get<dynamic>('/api/v1/homes/my-homes');
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
          .map((json) => DeviceDto.fromJson(Map<String, dynamic>.from(json)).toDomain())
          .toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Device> getDeviceById(String id) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/v1/devices/$id',
      );
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
  Future<Device> cancelDeviceAutomation(String id, {int minutes = 30}) async {
    try {
      final response = await _client.post<dynamic>(
        '/api/v1/devices/$id/automation/cancel',
        data: {'minutes': minutes},
      );
      final raw = response.data;
      final until = raw is Map ? (raw['result'] ?? raw['data'])?.toString() : null;
      final current = await getDeviceById(id);
      return current.copyWith(
        manualOverrideUntil: until ?? DateTime.now().add(Duration(minutes: minutes)).toIso8601String(),
        manualOverrideActive: true,
      );
    } on DioException catch (error) {
      throw mapDioException(error);
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
  Future<List<Map<String, dynamic>>> getDeviceAuditHistory(String id) async {
    try {
      final response = await _client.get<dynamic>('/api/v1/devices/$id/history');
      final raw = response.data;
      final data = raw is Map ? (raw['result'] ?? raw['data']) : null;
      if (data is List && data.isNotEmpty) {
        return data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      }
      return MockDeviceRepository().getDeviceAuditHistory(id);
    } catch (_) {
      return MockDeviceRepository().getDeviceAuditHistory(id);
    }
  }

  @override
  Future<String> exportDeviceAuditExcel(String id, String deviceName) async {
    try {
      final response = await _client.dio.get<List<int>>(
        '/api/v1/devices/$id/history/export/excel',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      final bytes = response.data ?? <int>[];
      final sanitized = deviceName.replaceAll(RegExp(r'\s+'), '_');
      if (bytes.isNotEmpty) {
        try {
          final file = File('/sdcard/Download/lich_su_${sanitized}_$id.xlsx');
          await file.writeAsBytes(bytes);
          return file.path;
        } catch (_) {
          return 'lich_su_${sanitized}_$id.xlsx (${bytes.length} bytes)';
        }
      }
      return MockDeviceRepository().exportDeviceAuditExcel(id, deviceName);
    } catch (_) {
      return MockDeviceRepository().exportDeviceAuditExcel(id, deviceName);
    }
  }

  @override
  Future<Device> updateDeviceWattage(String id, double wattage) async {
    try {
      final response = await _client.dio.put<dynamic>(
        '/api/v1/devices/$id',
        data: {
          'settings': {'wattage': wattage.toInt()},
        },
      );
      return _deviceFrom(response).copyWith(energyWatts: wattage);
    } catch (_) {
      return MockDeviceRepository().updateDeviceWattage(id, wattage);
    }
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
