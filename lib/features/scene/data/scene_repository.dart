import '../../../core/network/network_client.dart';
import '../domain/scene.dart';

class SceneRepository {
  SceneRepository({required this.client});

  final NetworkClient client;

  Future<List<Scene>> getScenes(String homeId) async {
    final response = await client.get<dynamic>('/api/v1/homes/$homeId/scenes');
    final body = response.data;
    final list = _extractList(body);
    return list
        .whereType<Map>()
        .map((m) => Scene.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Scene> getScene(String homeId, String sceneId) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/scenes/$sceneId',
    );
    final body = response.data;
    final data = _extractMap(body);
    return Scene.fromJson(data);
  }

  Future<Scene> createScene(
    String homeId, {
    required String name,
    String? icon,
    String? description,
    bool enabled = true,
    List<SceneAction> actions = const [],
  }) async {
    final payload = {
      'name': name,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
      'enabled': enabled,
      // Backend needs contiguous orders from 0; list position is the source of truth.
      'actions': [
        for (final (i, a) in actions.indexed) {...a.toJson(), 'order': i},
      ],
    };

    final response = await client.post<dynamic>(
      '/api/v1/homes/$homeId/scenes',
      data: payload,
    );
    final data = _extractMap(response.data);
    return Scene.fromJson(data);
  }

  Future<Scene> updateScene(
    String homeId,
    String sceneId, {
    required String name,
    String? icon,
    String? description,
    required bool enabled,
    List<SceneAction>? actions,
  }) async {
    final payload = {
      'name': name,
      'icon': icon,
      'description': description,
      'enabled': enabled,
      if (actions != null)
        'actions': [
          for (final (i, a) in actions.indexed) {...a.toJson(), 'order': i},
        ],
    };

    final response = await client.put<dynamic>(
      '/api/v1/homes/$homeId/scenes/$sceneId',
      data: payload,
    );
    final data = _extractMap(response.data);
    return Scene.fromJson(data);
  }

  Future<void> deleteScene(String homeId, String sceneId) async {
    await client.dio.delete<dynamic>('/api/v1/homes/$homeId/scenes/$sceneId');
  }

  Future<SceneExecution> executeScene(String homeId, String sceneId) async {
    final response = await client.post<dynamic>(
      '/api/v1/homes/$homeId/scenes/$sceneId/execute',
    );
    final data = _extractMap(response.data);
    return SceneExecution.fromJson(data);
  }

  /// Runs the scene once after [delaySeconds] (1s..24h); replaces a pending timer. Returns the run time.
  Future<DateTime> runLater(
    String homeId,
    String sceneId,
    int delaySeconds,
  ) async {
    final response = await client.dio.post<dynamic>(
      '/api/v1/homes/$homeId/scenes/$sceneId/run-later',
      queryParameters: {'delaySeconds': delaySeconds},
    );
    final body = response.data;
    final raw = body is Map ? body['result'] : body;
    return DateTime.parse(raw.toString());
  }

  Future<void> cancelRunLater(String homeId, String sceneId) async {
    await client.dio.delete<dynamic>(
      '/api/v1/homes/$homeId/scenes/$sceneId/run-later',
    );
  }

  Future<List<SceneExecution>> getExecutions(
    String homeId,
    String sceneId,
  ) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/scenes/$sceneId/executions',
    );
    final list = _extractList(response.data);
    return list
        .whereType<Map>()
        .map((m) => SceneExecution.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<SceneSchedule>> getSchedules(
    String homeId,
    String sceneId,
  ) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/scenes/$sceneId/schedules',
    );
    final list = _extractList(response.data);
    return list
        .whereType<Map>()
        .map((m) => SceneSchedule.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<SceneSchedule> saveSchedule(
    String homeId,
    String sceneId, {
    String? scheduleId,
    required String time,
    required List<int> repeatDays,
    required bool enabled,
  }) async {
    final payload = {
      'scheduledTime': time,
      'repeatDays': repeatDays,
      'active': enabled,
    };

    if (scheduleId == null) {
      final response = await client.post<dynamic>(
        '/api/v1/homes/$homeId/scenes/$sceneId/schedules',
        data: payload,
      );
      return SceneSchedule.fromJson(_extractMap(response.data));
    } else {
      final response = await client.put<dynamic>(
        '/api/v1/homes/$homeId/scenes/$sceneId/schedules/$scheduleId',
        data: payload,
      );
      return SceneSchedule.fromJson(_extractMap(response.data));
    }
  }

  Future<void> deleteSchedule(
    String homeId,
    String sceneId,
    String scheduleId,
  ) async {
    await client.dio.delete<dynamic>(
      '/api/v1/homes/$homeId/scenes/$sceneId/schedules/$scheduleId',
    );
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
