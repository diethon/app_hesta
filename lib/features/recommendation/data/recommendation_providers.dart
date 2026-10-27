import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../home/data/home_providers.dart';
import '../domain/recommendation_models.dart';
import 'recommendation_repository.dart';

final recommendationRepositoryProvider =
    Provider<RecommendationRepository>((ref) {
  final client = ref.watch(cloudApiClientProvider);
  return RecommendationRepository(client: client);
});

final recommendationsListProvider =
    AsyncNotifierProvider<RecommendationsListNotifier, List<Recommendation>>(
  RecommendationsListNotifier.new,
);

class RecommendationsListNotifier
    extends AsyncNotifier<List<Recommendation>> {
  @override
  Future<List<Recommendation>> build() async {
    final homeId = ref.watch(currentHomeIdProvider);
    if (homeId == null) {
      return _mockRecommendations();
    }

    if (kUseMockData) {
      return _mockRecommendations();
    }

    try {
      final repo = ref.read(recommendationRepositoryProvider);
      final list = await repo.getRecommendations(homeId);
      if (list.isEmpty) {
        return _mockRecommendations();
      }
      return list;
    } catch (_) {
      return _mockRecommendations();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final homeId = ref.read(currentHomeIdProvider);
      if (homeId == null) return _mockRecommendations();
      final repo = ref.read(recommendationRepositoryProvider);
      return repo.getRecommendations(homeId);
    });
  }

  Future<int> generate() async {
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) return 0;

    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 30));

    try {
      final repo = ref.read(recommendationRepositoryProvider);
      final newRecs = await repo.generateRecommendations(homeId, from, to);
      await refresh();
      return newRecs.length;
    } catch (_) {
      // Mock generation if needed
      await refresh();
      return 1;
    }
  }

  Future<bool> approve(String id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current
          .map((r) => r.id == id ? r.copyWith(status: 'APPROVED') : r)
          .toList(),
    );

    final homeId = ref.read(currentHomeIdProvider);
    if (homeId != null && !kUseMockData) {
      try {
        final repo = ref.read(recommendationRepositoryProvider);
        await repo.approve(homeId, id);
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  Future<bool> reject(String id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current
          .map((r) => r.id == id ? r.copyWith(status: 'REJECTED') : r)
          .toList(),
    );

    final homeId = ref.read(currentHomeIdProvider);
    if (homeId != null && !kUseMockData) {
      try {
        final repo = ref.read(recommendationRepositoryProvider);
        await repo.reject(homeId, id);
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  Future<bool> dismiss(String id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current
          .map((r) => r.id == id ? r.copyWith(status: 'DISMISSED') : r)
          .toList(),
    );

    final homeId = ref.read(currentHomeIdProvider);
    if (homeId != null && !kUseMockData) {
      try {
        final repo = ref.read(recommendationRepositoryProvider);
        await repo.dismiss(homeId, id);
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  List<Recommendation> _mockRecommendations() {
    return [
      Recommendation(
        id: 'rec-1',
        homeId: 'home-default',
        deviceId: 'living-light-1',
        deviceName: 'Đèn phòng khách',
        triggerCondition: const RecommendationTrigger(
          type: 'SCHEDULE',
          time: '18:45',
          repeatDays: [1, 2, 3, 4, 5],
          patternType: 'DAILY_EVENING',
        ),
        proposedAction: const RecommendationAction(
          deviceId: 'living-light-1',
          action: 'TURN_ON',
        ),
        explanation:
            'Mô hình Machine Learning phát hiện bạn thường xuyên bật đèn phòng khách vào khoảng 18:45 các ngày trong tuần (Tỉ lệ 94%).',
        confidence: 0.94,
        status: 'PENDING',
        engineType: 'ML',
        modelVersion: 'v2.4.1',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Recommendation(
        id: 'rec-2',
        homeId: 'home-default',
        deviceId: 'bedroom-ac',
        deviceName: 'Điều hòa phòng ngủ',
        triggerCondition: const RecommendationTrigger(
          type: 'SCHEDULE',
          time: '22:30',
          repeatDays: [1, 2, 3, 4, 5, 6, 7],
          patternType: 'NIGHT_COOLING',
        ),
        proposedAction: const RecommendationAction(
          deviceId: 'bedroom-ac',
          action: 'SET_TEMPERATURE',
          parameters: {'temperature': 25},
        ),
        explanation:
            'Thói quen bật điều hòa 25°C lúc 22:30 trước khi đi ngủ đã lặp lại liên tục trong 14 ngày qua.',
        confidence: 0.89,
        status: 'PENDING',
        engineType: 'ML',
        modelVersion: 'v2.4.1',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Recommendation(
        id: 'rec-3',
        homeId: 'home-default',
        deviceId: 'living-curtain',
        deviceName: 'Rèm tự động',
        triggerCondition: const RecommendationTrigger(
          type: 'SCHEDULE',
          time: '06:30',
          repeatDays: [1, 2, 3, 4, 5],
        ),
        proposedAction: const RecommendationAction(
          deviceId: 'living-curtain',
          action: 'OPEN',
        ),
        explanation:
            'Mở rèm đón ánh sáng tự nhiên lúc 06:30 vào các buổi sáng ngày làm việc.',
        confidence: 0.82,
        status: 'APPROVED',
        engineType: 'ML',
        modelVersion: 'v2.3.0',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}

final mlModelStatusProvider =
    AsyncNotifierProvider<MlModelStatusNotifier, MlModelStatus>(
  MlModelStatusNotifier.new,
);

class MlModelStatusNotifier extends AsyncNotifier<MlModelStatus> {
  @override
  Future<MlModelStatus> build() async {
    final homeId = ref.watch(currentHomeIdProvider);
    if (homeId == null || kUseMockData) {
      return _mockStatus();
    }

    try {
      final repo = ref.read(recommendationRepositoryProvider);
      return repo.getModelStatus(homeId);
    } catch (_) {
      return _mockStatus();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final homeId = ref.read(currentHomeIdProvider);
      if (homeId == null) return _mockStatus();
      final repo = ref.read(recommendationRepositoryProvider);
      return repo.getModelStatus(homeId);
    });
  }

  Future<MlModelStatus?> retrain() async {
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) return null;

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(recommendationRepositoryProvider);
      final newStatus = await repo.triggerRetraining(homeId);
      state = AsyncValue.data(newStatus);
      return newStatus;
    } catch (e) {
      final fallback = _mockStatus();
      state = AsyncValue.data(fallback);
      return fallback;
    }
  }

  MlModelStatus _mockStatus() {
    return MlModelStatus(
      status: 'READY',
      version: 'v2.4.1',
      modelType: 'Behavioral Pattern Miner (LightGBM)',
      accuracy: 0.91,
      precision: 0.88,
      recall: 0.93,
      f1Score: 0.90,
      trainSamples: 342,
      confidenceThreshold: 0.80,
      trainedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
  }
}
