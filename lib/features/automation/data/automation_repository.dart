import '../../../core/network/network_client.dart';
import '../domain/automation_models.dart';

class AutomationRepository {
  AutomationRepository({required this.client});

  final NetworkClient client;

  Future<List<AutomationRule>> getRules(String homeId) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/automation-rules',
    );
    final list = _extractList(response.data);
    return list
        .whereType<Map>()
        .map((m) => AutomationRule.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<AutomationRule> getRule(String homeId, String ruleId) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/automation-rules/$ruleId',
    );
    return AutomationRule.fromJson(_extractMap(response.data));
  }

  Future<AutomationRule> createRule(
    String homeId, {
    required String name,
    String? description,
    required String triggerType,
    required bool enabled,
    required List<RuleCondition> conditions,
    required List<RuleAction> actions,
  }) async {
    final payload = {
      'name': name,
      if (description != null) 'description': description,
      'triggerType': triggerType,
      'enabled': enabled,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
    };

    final response = await client.post<dynamic>(
      '/api/v1/homes/$homeId/automation-rules',
      data: payload,
    );
    return AutomationRule.fromJson(_extractMap(response.data));
  }

  Future<AutomationRule> updateRule(
    String homeId,
    String ruleId, {
    required String name,
    String? description,
    required String triggerType,
    required bool enabled,
    required List<RuleCondition> conditions,
    required List<RuleAction> actions,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'triggerType': triggerType,
      'enabled': enabled,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
    };

    final response = await client.put<dynamic>(
      '/api/v1/homes/$homeId/automation-rules/$ruleId',
      data: payload,
    );
    return AutomationRule.fromJson(_extractMap(response.data));
  }

  Future<AutomationRule> setEnabled(
    String homeId,
    String ruleId,
    bool enabled,
  ) async {
    final response = await client.dio.patch<dynamic>(
      '/api/v1/homes/$homeId/automation-rules/$ruleId/enabled',
      queryParameters: {'enabled': enabled},
    );
    return AutomationRule.fromJson(_extractMap(response.data));
  }

  Future<void> deleteRule(String homeId, String ruleId) async {
    await client.dio.delete<dynamic>(
      '/api/v1/homes/$homeId/automation-rules/$ruleId',
    );
  }

  Future<List<AutomationExecution>> getExecutions(
    String homeId,
    String ruleId,
  ) async {
    final response = await client.get<dynamic>(
      '/api/v1/homes/$homeId/automation-rules/$ruleId/executions',
    );
    final list = _extractList(response.data);
    return list
        .whereType<Map>()
        .map((m) => AutomationExecution.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Map<String, dynamic>> testRule(
    String homeId,
    String ruleId, {
    Map<String, dynamic>? eventData,
  }) async {
    final response = await client.post<dynamic>(
      '/api/v1/homes/$homeId/automation-rules/$ruleId/test',
      data: eventData ?? {},
    );
    return _extractMap(response.data);
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
