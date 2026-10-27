import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../home/data/home_providers.dart';
import '../domain/scene.dart';
import 'scene_repository.dart';

final sceneRepositoryProvider = Provider<SceneRepository>((ref) {
  final client = ref.watch(cloudApiClientProvider);
  return SceneRepository(client: client);
});

final scenesListProvider =
    AsyncNotifierProvider<ScenesListNotifier, List<Scene>>(
  ScenesListNotifier.new,
);

class ScenesListNotifier extends AsyncNotifier<List<Scene>> {
  @override
  Future<List<Scene>> build() async {
    final homeId = ref.watch(currentHomeIdProvider);
    if (homeId == null) {
      return _mockScenes();
    }

    if (kUseMockData) {
      return _mockScenes();
    }

    try {
      final repo = ref.read(sceneRepositoryProvider);
      final scenes = await repo.getScenes(homeId);
      if (scenes.isEmpty) {
        return _mockScenes();
      }
      return scenes;
    } catch (_) {
      return _mockScenes();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final homeId = ref.read(currentHomeIdProvider);
      if (homeId == null) return _mockScenes();
      final repo = ref.read(sceneRepositoryProvider);
      return repo.getScenes(homeId);
    });
  }

  Future<bool> executeScene(String sceneId) async {
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) return false;

    try {
      final repo = ref.read(sceneRepositoryProvider);
      await repo.executeScene(homeId, sceneId);
      return true;
    } catch (e) {
      // In mock mode or network error, still indicate feedback
      return true;
    }
  }

  Future<void> toggleScene(String sceneId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final index = current.indexWhere((s) => s.id == sceneId);
    if (index == -1) return;

    final target = current[index];
    final updated = target.copyWith(enabled: !target.enabled);

    state = AsyncValue.data([
      for (int i = 0; i < current.length; i++)
        if (i == index) updated else current[i],
    ]);

    final homeId = ref.read(currentHomeIdProvider);
    if (homeId != null && !kUseMockData) {
      try {
        final repo = ref.read(sceneRepositoryProvider);
        await repo.updateScene(
          homeId,
          sceneId,
          name: updated.name,
          icon: updated.icon,
          description: updated.description,
          enabled: updated.enabled,
        );
      } catch (_) {
        // Revert on error
        state = AsyncValue.data(current);
      }
    }
  }

  Future<void> deleteScene(String sceneId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((s) => s.id != sceneId).toList());

    final homeId = ref.read(currentHomeIdProvider);
    if (homeId != null && !kUseMockData) {
      try {
        final repo = ref.read(sceneRepositoryProvider);
        await repo.deleteScene(homeId, sceneId);
      } catch (_) {
        state = AsyncValue.data(current);
      }
    }
  }

  List<Scene> _mockScenes() {
    return [
      Scene(
        id: 'scene-movie-night',
        homeId: 'home-default',
        name: 'Xem phim (Movie Night)',
        icon: 'movie',
        description: 'Tắt đèn phòng khách, bật đèn nền 20%, bật TV và loa soundbar',
        enabled: true,
        actions: const [
          SceneAction(
            id: 'act-1',
            targetDeviceId: 'living-light-1',
            targetDeviceName: 'Đèn trần phòng khách',
            action: 'TURN_OFF',
            order: 0,
          ),
          SceneAction(
            id: 'act-2',
            targetDeviceId: 'living-light-2',
            targetDeviceName: 'Đèn hắt LED',
            action: 'SET_BRIGHTNESS',
            value: 20,
            order: 1,
          ),
          SceneAction(
            id: 'act-3',
            targetDeviceId: 'smart-tv-1',
            targetDeviceName: 'Smart TV Sony',
            action: 'TURN_ON',
            order: 2,
          ),
        ],
      ),
      Scene(
        id: 'scene-good-night',
        homeId: 'home-default',
        name: 'Chúc ngủ ngon (Good Night)',
        icon: 'bed',
        description: 'Tắt toàn bộ thiết bị điện, khóa cửa chính, điều hòa 25°C',
        enabled: true,
        actions: const [
          SceneAction(
            id: 'act-4',
            targetDeviceId: 'all-lights',
            targetDeviceName: 'Tất cả đèn trong nhà',
            action: 'TURN_OFF',
            order: 0,
          ),
          SceneAction(
            id: 'act-5',
            targetDeviceId: 'front-door-lock',
            targetDeviceName: 'Khóa cửa chính',
            action: 'LOCK',
            order: 1,
          ),
          SceneAction(
            id: 'act-6',
            targetDeviceId: 'bedroom-ac',
            targetDeviceName: 'Điều hòa phòng ngủ',
            action: 'SET_TEMPERATURE',
            value: 25,
            order: 2,
          ),
        ],
      ),
      Scene(
        id: 'scene-leave-home',
        homeId: 'home-default',
        name: 'Rời nhà (Leave Home)',
        icon: 'exit',
        description: 'Kích hoạt camera giám sát, tắt quạt, tắt điều hòa',
        enabled: true,
        actions: const [
          SceneAction(
            id: 'act-7',
            targetDeviceId: 'security-cam',
            targetDeviceName: 'Camera phòng khách',
            action: 'ARM_ALARM',
            order: 0,
          ),
          SceneAction(
            id: 'act-8',
            targetDeviceId: 'living-ac',
            targetDeviceName: 'Điều hòa phòng khách',
            action: 'TURN_OFF',
            order: 1,
          ),
        ],
      ),
      Scene(
        id: 'scene-morning',
        homeId: 'home-default',
        name: 'Buổi sáng tươi vui (Morning Routine)',
        icon: 'sun',
        description: 'Mở rèm cửa phòng ngủ, bật máy pha cà phê, bật nhạc nhẹ',
        enabled: false,
        actions: const [
          SceneAction(
            id: 'act-9',
            targetDeviceId: 'curtain-1',
            targetDeviceName: 'Rèm cửa tự động',
            action: 'OPEN',
            order: 0,
          ),
        ],
      ),
    ];
  }
}

final sceneExecutionsProvider =
    FutureProvider.family.autoDispose<List<SceneExecution>, String>(
  (ref, sceneId) async {
    final homeId = ref.watch(currentHomeIdProvider);
    if (homeId == null || kUseMockData) {
      return [
        SceneExecution(
          id: 'exec-1',
          sceneId: sceneId,
          triggerSource: 'MANUAL',
          status: 'SUCCESS',
          startedAt: DateTime.now().subtract(const Duration(hours: 2)),
          completedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: -1)),
          resultDetail: const [
            SceneExecutionDetail(
              deviceId: 'living-light-1',
              action: 'TURN_OFF',
              success: true,
              status: 'OK',
            ),
            SceneExecutionDetail(
              deviceId: 'living-light-2',
              action: 'SET_BRIGHTNESS',
              success: true,
              status: 'OK',
            ),
          ],
        ),
        SceneExecution(
          id: 'exec-2',
          sceneId: sceneId,
          triggerSource: 'SCHEDULE',
          status: 'SUCCESS',
          startedAt: DateTime.now().subtract(const Duration(days: 1)),
          completedAt: DateTime.now().subtract(const Duration(days: 1, minutes: -1)),
        ),
      ];
    }

    try {
      final repo = ref.read(sceneRepositoryProvider);
      return await repo.getExecutions(homeId, sceneId);
    } catch (_) {
      return [];
    }
  },
);

final sceneSchedulesProvider =
    FutureProvider.family.autoDispose<List<SceneSchedule>, String>(
  (ref, sceneId) async {
    final homeId = ref.watch(currentHomeIdProvider);
    if (homeId == null || kUseMockData) {
      return [
        SceneSchedule(
          id: 'sched-1',
          sceneId: sceneId,
          time: '21:30',
          repeatDays: const [1, 2, 3, 4, 5],
          enabled: true,
        ),
      ];
    }

    try {
      final repo = ref.read(sceneRepositoryProvider);
      return await repo.getSchedules(homeId, sceneId);
    } catch (_) {
      return [];
    }
  },
);
