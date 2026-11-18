import 'package:dio/dio.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/network/network_client.dart';
import '../domain/camera_repository.dart';
import '../domain/fall_incident.dart';

class ApiCameraRepository implements CameraRepository {
  ApiCameraRepository(this._client, {String? aiEdgeBaseUrl})
    : _aiEdgeUrl = aiEdgeBaseUrl ?? 'http://10.0.2.2:5000';

  final NetworkClient _client;
  final String _aiEdgeUrl;
  final Dio _edgeDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
    ),
  );

  @override
  Future<List<FallIncident>> getActiveIncidents(String? homeId) async {
    try {
      final path = homeId != null && homeId.isNotEmpty
          ? '/api/v1/emergency/fall/active?homeId=$homeId'
          : '/api/v1/emergency/fall/active';

      final response = await _client.get<dynamic>(path);
      final rawData = response.data;
      final body = rawData is Map
          ? (rawData['result'] ?? rawData['data'] ?? rawData)
          : rawData;

      if (body is List) {
        return body
            .whereType<Map<String, dynamic>>()
            .map((json) => FallIncident.fromJson(json))
            .toList();
      }
      return const <FallIncident>[];
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      return const <FallIncident>[];
    }
  }

  @override
  Future<void> dismissIncident(
    String id, {
    String note = 'Người dùng bấm xác nhận an toàn (Tôi ổn)',
  }) async {
    try {
      await _client.post<dynamic>(
        '/api/v1/emergency/fall/$id/dismiss',
        data: {'note': note},
      );
    } catch (_) {
      // Ignored for offline fallback
    }
    // Also notify local AI engine
    await dismissAiLocal();
  }

  @override
  Future<void> acknowledgeIncident(String id) async {
    try {
      await _client.post<dynamic>('/api/v1/emergency/fall/$id/acknowledge');
    } catch (_) {
      // Ignored
    }
  }

  @override
  Future<void> resolveIncident(
    String id, {
    String note = 'Đã cấp cứu an toàn',
  }) async {
    try {
      await _client.post<dynamic>(
        '/api/v1/emergency/fall/$id/resolve',
        data: {'note': note},
      );
    } catch (_) {
      // Ignored
    }
  }

  @override
  Future<AiStatus?> checkAiStatus() async {
    try {
      final res = await _edgeDio.get<dynamic>('$_aiEdgeUrl/api/status');
      if (res.data is Map<String, dynamic>) {
        return AiStatus.fromJson(res.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> triggerDemoFall() async {
    try {
      final res = await _edgeDio.post<dynamic>(
        '$_aiEdgeUrl/api/trigger_demo_fall',
      );
      if (res.data is Map) {
        return res.data['success'] == true || res.data['status'] == 'ok';
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> dismissAiLocal() async {
    try {
      final res = await _edgeDio.post<dynamic>('$_aiEdgeUrl/api/dismiss');
      if (res.data is Map) {
        return res.data['success'] == true || res.data['status'] == 'ok';
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
