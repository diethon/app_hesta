import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../home/data/home_providers.dart';
import '../domain/device_group.dart';
import '../domain/device_group_repository.dart';
import 'api_device_group_repository.dart';
import 'mock_device_group_repository.dart';

final deviceGroupRepositoryProvider = Provider<DeviceGroupRepository>((ref) {
  if (kUseMockData) {
    return MockDeviceGroupRepository();
  }
  return ApiDeviceGroupRepository(ref.watch(cloudApiClientProvider));
});

class DeviceGroupsState {
  const DeviceGroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<DeviceGroup> groups;
  final bool isLoading;
  final String? errorMessage;

  DeviceGroupsState copyWith({
    List<DeviceGroup>? groups,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DeviceGroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DeviceGroupsController extends StateNotifier<DeviceGroupsState> {
  DeviceGroupsController(this._repository, this._ref)
    : super(const DeviceGroupsState()) {
    loadGroups();
  }

  final DeviceGroupRepository _repository;
  final Ref _ref;
  final Map<String, Timer> _debounceTimers = {};

  String get _currentHomeId =>
      _ref.read(currentHomeIdProvider) ?? 'home-mock-1';

  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final groups = await _repository.getGroups(_currentHomeId);
      if (groups.isNotEmpty) {
        state = state.copyWith(groups: groups, isLoading: false);
      } else {
        final mockRepo = MockDeviceGroupRepository();
        final demoGroups = await mockRepo.getGroups(_currentHomeId);
        state = state.copyWith(groups: demoGroups, isLoading: false);
      }
    } catch (_) {
      final mockRepo = MockDeviceGroupRepository();
      final demoGroups = await mockRepo.getGroups(_currentHomeId);
      state = state.copyWith(groups: demoGroups, isLoading: false);
    }
  }

  Future<bool> createGroup({
    required String name,
    required List<String> deviceIds,
    String? icon,
  }) async {
    try {
      final newGroup = await _repository.createGroup(
        homeId: _currentHomeId,
        name: name,
        deviceIds: deviceIds,
        icon: icon,
      );
      state = state.copyWith(groups: [...state.groups, newGroup]);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Lỗi tạo nhóm: $e');
      return false;
    }
  }

  Future<bool> updateGroup({
    required String groupId,
    required String name,
    required List<String> deviceIds,
    String? icon,
  }) async {
    try {
      final updated = await _repository.updateGroup(
        groupId: groupId,
        name: name,
        deviceIds: deviceIds,
        icon: icon,
      );
      state = state.copyWith(
        groups: [
          for (final group in state.groups)
            group.id == groupId ? updated : group,
        ],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Lỗi cập nhật nhóm: $e');
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    _debounceTimers[groupId]?.cancel();
    _debounceTimers.remove(groupId);

    try {
      await _repository.deleteGroup(groupId);
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != groupId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Lỗi xóa nhóm: $e');
      return false;
    }
  }

  Future<void> toggleGroupPower(String groupId, bool turnOn) async {
    _debounceTimers[groupId]?.cancel();
    _debounceTimers.remove(groupId);

    _setGroupExecuting(groupId, true, 'Đang gửi lệnh đồng thời...');

    final action = turnOn ? 'TURN_ON' : 'TURN_OFF';
    try {
      final res = await _repository.sendGroupCommand(
        groupId: groupId,
        action: action,
      );

      final msg = res.isSuccess
          ? '✓ ${res.successCount}/${res.totalDevices} thiết bị thành công'
          : '⚠ 0/${res.totalDevices} thiết bị phản hồi';

      _updateGroupFeedback(groupId, msg);
    } catch (e) {
      _updateGroupFeedback(groupId, 'Lỗi thực thi lệnh: $e');
    } finally {
      _setGroupExecuting(groupId, false, null);
    }
  }

  void setGroupBrightness(String groupId, int brightness) {
    // 1. Cập nhật UI ngay lập tức (optimistic update)
    final idx = state.groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final updatedList = List<DeviceGroup>.from(state.groups);
      updatedList[idx] = updatedList[idx].copyWith(
        currentBrightness: brightness,
      );
      state = state.copyWith(groups: updatedList);
    }

    // 2. Debounce backend network call by 350ms to prevent spamming MQTT
    _debounceTimers[groupId]?.cancel();
    _debounceTimers[groupId] = Timer(const Duration(milliseconds: 350), () async {
      _setGroupExecuting(groupId, true, 'Đang chỉnh độ sáng...');
      try {
        final res = await _repository.sendGroupCommand(
          groupId: groupId,
          action: 'SET_BRIGHTNESS',
          parameters: {'brightness': brightness},
        );

        final msg = res.isSuccess
            ? '✓ Độ sáng $brightness% (${res.successCount}/${res.totalDevices})'
            : '⚠ Không có thiết bị nào áp dụng';

        _updateGroupFeedback(groupId, msg);
      } catch (e) {
        _updateGroupFeedback(groupId, 'Lỗi độ sáng: $e');
      } finally {
        _setGroupExecuting(groupId, false, null);
      }
    });
  }

  void _setGroupExecuting(String groupId, bool isExecuting, String? message) {
    final idx = state.groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final updatedList = List<DeviceGroup>.from(state.groups);
      updatedList[idx] = updatedList[idx].copyWith(
        isExecuting: isExecuting,
        statusMessage: message ?? updatedList[idx].statusMessage,
      );
      state = state.copyWith(groups: updatedList);
    }
  }

  void _updateGroupFeedback(String groupId, String message) {
    final idx = state.groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final updatedList = List<DeviceGroup>.from(state.groups);
      updatedList[idx] = updatedList[idx].copyWith(statusMessage: message);
      state = state.copyWith(groups: updatedList);

      // Auto-clear message after 4s (matching web)
      Timer(const Duration(seconds: 4), () {
        final curIdx = state.groups.indexWhere((g) => g.id == groupId);
        if (curIdx != -1 && state.groups[curIdx].statusMessage == message) {
          final clearedList = List<DeviceGroup>.from(state.groups);
          clearedList[curIdx] = clearedList[curIdx].copyWith(
            statusMessage: null,
          );
          state = state.copyWith(groups: clearedList);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    super.dispose();
  }
}

final deviceGroupsControllerProvider =
    StateNotifierProvider<DeviceGroupsController, DeviceGroupsState>((ref) {
      final repo = ref.watch(deviceGroupRepositoryProvider);
      return DeviceGroupsController(repo, ref);
    });
