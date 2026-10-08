import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../../core/services/websocket_service.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../home/data/home_providers.dart';
import '../domain/device.dart';
import '../domain/device_repository.dart';
import 'api_device_repository.dart';
import 'mock_device_repository.dart';
import 'models/device_dto.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  if (kUseMockData) {
    return MockDeviceRepository();
  }
  return ApiDeviceRepository(
    ref.watch(cloudApiClientProvider),
    getHomeId: () => ref.read(currentHomeIdProvider),
  );
});

/// Trạng thái realtime của một thiết bị từ topic `/topic/homes/{homeId}/events`.
final deviceStateStreamProvider = StreamProvider.family<Device, String>((
  ref,
  deviceId,
) {
  if (kUseMockData) {
    return const Stream<Device>.empty();
  }
  final homeId = ref.watch(currentHomeIdProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);

  if (homeId != null) {
    return webSocketService
        .subscribeJson('/topic/homes/$homeId/events')
        .where((event) {
          final type = event['type']?.toString();
          if (type != 'DEVICE_STATE_CHANGED' && type != 'SENSOR_READING_UPDATED') {
            return false;
          }
          final evDevId = event['deviceId']?.toString();
          final data = event['data'];
          final dataDevId = data is Map<String, dynamic>
              ? (data['id'] ?? data['deviceId'])?.toString()
              : null;
          return evDevId == deviceId || dataDevId == deviceId;
        })
        .map((event) {
          final data = event['data'];
          if (data is Map<String, dynamic>) {
            return DeviceDto.fromJson(data).toDomain();
          }
          return DeviceDto.fromJson(event).toDomain();
        });
  }

  return webSocketService
      .subscribeJson('/topic/devices/$deviceId/state')
      .map((json) => DeviceDto.fromJson(json).toDomain());
});

final devicesControllerProvider =
    StateNotifierProvider<DevicesController, AsyncValue<List<Device>>>((ref) {
      final homeId = ref.watch(currentHomeIdProvider);
      final controller = DevicesController(
        ref.watch(deviceRepositoryProvider),
        homeId: homeId,
        realtime: kUseMockData ? null : ref.watch(webSocketServiceProvider),
      )..load();
      return controller;
    });

class DevicesController extends StateNotifier<AsyncValue<List<Device>>> {
  DevicesController(
    this._repository, {
    this.homeId,
    WebSocketService? realtime,
  }) : _realtime = realtime,
       super(const AsyncValue.loading());

  final DeviceRepository _repository;
  final String? homeId;
  final WebSocketService? _realtime;
  final List<StreamSubscription<Map<String, dynamic>>> _realtimeSubs = [];

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getDevices);
    _subscribeRealtime();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.getDevices);
    _subscribeRealtime();
  }

  Future<void> updateDevice(String id, DeviceCommand command) async {
    final previous = state.valueOrNull ?? const <Device>[];
    final updated = await _repository.updateDeviceState(id, command);
    state = AsyncValue.data([
      for (final device in previous) device.id == id ? updated : device,
    ]);
  }

  void _subscribeRealtime() {
    final realtime = _realtime;
    final devices = state.valueOrNull;
    if (realtime == null || devices == null) {
      return;
    }
    for (final subscription in _realtimeSubs) {
      subscription.cancel();
    }
    _realtimeSubs.clear();

    // 1. Topic chuẩn theo kiến trúc backend_hesta: /topic/homes/{homeId}/events
    if (homeId != null) {
      _realtimeSubs.add(
        realtime
            .subscribeJson('/topic/homes/$homeId/events')
            .listen((event) {
              final type = event['type']?.toString();
              final data = event['data'];
              if (data is! Map<String, dynamic>) return;

              if (type == 'SENSOR_READING_UPDATED') {
                _applySensorReadingUpdate(data);
              } else if (type == 'DEVICE_STATE_CHANGED') {
                _applyRealtimeUpdate(data);
              }
            }),
      );
    }

    // 2. Kênh fallback
    for (final device in devices) {
      _realtimeSubs.add(
        realtime
            .subscribeJson('/topic/devices/${device.id}/state')
            .listen(_applyRealtimeUpdate),
      );
    }
  }

  void _applySensorReadingUpdate(Map<String, dynamic> data) {
    final devices = state.valueOrNull;
    if (devices == null) return;
    final devId = (data['deviceId'] ?? data['id'])?.toString();
    if (devId == null) return;

    final metricType = data['metricType']?.toString().toUpperCase();
    final value = (data['latestValue'] ?? data['value'] as num?)?.round();
    if (value == null) return;

    final isTemp = metricType == 'TEMPERATURE' || metricType == 'TEMP';
    final isHumid = metricType == 'HUMIDITY' || metricType == 'HUMID';

    state = AsyncValue.data([
      for (final device in devices)
        if (device.id == devId)
          device.copyWith(
            temperature: isTemp ? value : device.temperature,
            humidity: isHumid ? value : device.humidity,
          )
        else
          device,
    ]);
  }

  void _applyRealtimeUpdate(Map<String, dynamic> json) {
    final devices = state.valueOrNull;
    if (devices == null) {
      return;
    }
    final Device updated;
    try {
      updated = DeviceDto.fromJson(json).toDomain();
    } catch (_) {
      return;
    }
    state = AsyncValue.data([
      for (final device in devices)
        if (device.id == updated.id)
          device.copyWith(
            status: updated.status,
            isOn: updated.isOn,
            brightness: updated.brightness ?? device.brightness,
            temperature: updated.temperature ?? device.temperature,
            humidity: updated.humidity ?? device.humidity,
            energyWatts: updated.energyWatts ?? device.energyWatts,
            r: updated.r ?? device.r,
            g: updated.g ?? device.g,
            b: updated.b ?? device.b,
            acMode: updated.acMode ?? device.acMode,
            acFan: updated.acFan ?? device.acFan,
            acSwing: updated.acSwing ?? device.acSwing,
            timerEnabled: updated.timerEnabled ?? device.timerEnabled,
            timerHour: updated.timerHour ?? device.timerHour,
            timerHalfHour: updated.timerHalfHour ?? device.timerHalfHour,
          )
        else
          device,
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _realtimeSubs) {
      subscription.cancel();
    }
    _realtimeSubs.clear();
    super.dispose();
  }
}
