import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/network/network_client.dart';
import '../../home/data/home_providers.dart';
import '../domain/security_models.dart';

final securityRepositoryProvider = Provider<SecurityRepository>(
  (ref) => SecurityRepository(ref.watch(cloudApiClientProvider)),
);

/// Key: status filter (null = tất cả).
final anomaliesProvider = FutureProvider.autoDispose
    .family<List<DeviceAnomaly>, String?>((ref, status) {
      final homeId = ref.watch(currentHomeIdProvider);
      if (homeId == null) return const [];
      return ref.watch(securityRepositoryProvider).getAnomalies(homeId, status);
    });

final securityEventsProvider = FutureProvider.autoDispose
    .family<List<SecurityEvent>, String?>((ref, status) {
      final homeId = ref.watch(currentHomeIdProvider);
      if (homeId == null) return const [];
      return ref.watch(securityRepositoryProvider).getEvents(homeId, status);
    });

class SecurityRepository {
  SecurityRepository(this._client);

  final NetworkClient _client;

  Future<List<DeviceAnomaly>> getAnomalies(String homeId, String? status) =>
      _list('/api/v1/homes/$homeId/anomalies', status, DeviceAnomaly.fromJson);

  Future<List<SecurityEvent>> getEvents(String homeId, String? status) => _list(
    '/api/v1/homes/$homeId/security-events',
    status,
    SecurityEvent.fromJson,
  );

  Future<void> acknowledgeAnomaly(String homeId, String id) =>
      _put('/api/v1/homes/$homeId/anomalies/$id/acknowledge');

  Future<void> resolveAnomaly(
    String homeId,
    String id, {
    bool falsePositive = false,
    String? note,
  }) => _put('/api/v1/homes/$homeId/anomalies/$id/resolve', {
    'falsePositive': falsePositive,
    'note': ?note,
  });

  /// [action]: `confirm` hoặc `dismiss`.
  Future<void> updateEvent(String homeId, String id, String action) =>
      _put('/api/v1/homes/$homeId/security-events/$id/$action');

  Future<List<T>> _list<T>(
    String path,
    String? status,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': 0, 'size': 50, 'status': ?status},
      );
      final content = (response.data?['result'] as Map?)?['content'];
      if (content is! List) return const [];
      return content
          .whereType<Map>()
          .map((json) => fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<void> _put(String path, [Object? data]) async {
    try {
      await _client.put<void>(path, data: data);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
