import '../../../core/network/network_client.dart';
import '../domain/recommendation_models.dart';

class RecommendationRepository {
  RecommendationRepository({required this.client});

  final NetworkClient client;

  Future<List<Recommendation>> getRecommendations(String homeId) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/recommendations',
    );
    final list = _extractList(response.data);
    return list
        .whereType<Map>()
        .map((m) => Recommendation.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// The backend's pick for the home banner (pending, above the confidence threshold); null when there is none.
  Future<Recommendation?> getTopRecommendation(String homeId) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/recommendations/top',
    );
    final body = response.data;
    final result = body is Map ? body['result'] ?? body['data'] : null;
    return result is Map
        ? Recommendation.fromJson(Map<String, dynamic>.from(result))
        : null;
  }

  Future<List<Recommendation>> generateRecommendations(
    String homeId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await client.dio.post<dynamic>(
      '/api/v1/homes/$homeId/recommendations/generate',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    final list = _extractList(response.data);
    return list
        .whereType<Map>()
        .map((m) => Recommendation.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Recommendation> approve(String homeId, String recommendationId) async {
    final response = await client.post<dynamic>(
      '/api/v1/homes/$homeId/recommendations/$recommendationId/approve',
    );
    return Recommendation.fromJson(_extractMap(response.data));
  }

  Future<Recommendation> reject(String homeId, String recommendationId) async {
    final response = await client.post<dynamic>(
      '/api/v1/homes/$homeId/recommendations/$recommendationId/reject',
    );
    return Recommendation.fromJson(_extractMap(response.data));
  }

  Future<Recommendation> dismiss(String homeId, String recommendationId) async {
    final response = await client.post<dynamic>(
      '/api/v1/homes/$homeId/recommendations/$recommendationId/dismiss',
    );
    return Recommendation.fromJson(_extractMap(response.data));
  }

  Future<MlModelStatus> getModelStatus(String homeId) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/recommendations/model-status',
    );
    return MlModelStatus.fromJson(_extractMap(response.data));
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is Map) {
      final result = body['result'] ?? body['data'];
      if (result is List) return result;
    } else if (body is List) {
      return body;
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic body) {
    if (body is Map) {
      final result = body['result'] ?? body['data'];
      if (result is Map) return Map<String, dynamic>.from(result);
      return Map<String, dynamic>.from(body);
    }
    return <String, dynamic>{};
  }
}
