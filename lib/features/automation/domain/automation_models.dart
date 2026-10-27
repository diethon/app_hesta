import 'package:flutter/foundation.dart';

@immutable
class RuleCondition {
  const RuleCondition({
    this.id,
    this.deviceId,
    this.deviceName,
    required this.attribute,
    required this.operator,
    required this.expectedValue,
    this.logicalOperator = 'AND',
    this.order = 0,
  });

  final String? id;
  final String? deviceId;
  final String? deviceName;
  final String attribute;
  final String operator; // EQ, NE, GT, GTE, LT, LTE
  final dynamic expectedValue;
  final String logicalOperator; // AND, OR
  final int order;

  factory RuleCondition.fromJson(Map<String, dynamic> json) {
    return RuleCondition(
      id: json['id']?.toString(),
      deviceId: json['deviceId']?.toString(),
      deviceName: json['deviceName']?.toString(),
      attribute: (json['attribute'] ?? '').toString(),
      operator: (json['operator'] ?? 'EQ').toString(),
      expectedValue: json['expectedValue'],
      logicalOperator: (json['logicalOperator'] ?? 'AND').toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'deviceId': deviceId,
      'attribute': attribute,
      'operator': operator,
      'expectedValue': expectedValue,
      'logicalOperator': logicalOperator,
      'order': order,
    };
  }

  String get operatorSymbol {
    switch (operator.toUpperCase()) {
      case 'GT':
        return '>';
      case 'GTE':
        return '>=';
      case 'LT':
        return '<';
      case 'LTE':
        return '<=';
      case 'NE':
        return '!=';
      case 'EQ':
      default:
        return '=';
    }
  }
}

@immutable
class RuleAction {
  const RuleAction({
    this.id,
    this.deviceId,
    this.deviceName,
    this.sceneId,
    this.sceneName,
    required this.action,
    this.parameters = const {},
    this.order = 0,
  });

  final String? id;
  final String? deviceId;
  final String? deviceName;
  final String? sceneId;
  final String? sceneName;
  final String action;
  final Map<String, dynamic> parameters;
  final int order;

  factory RuleAction.fromJson(Map<String, dynamic> json) {
    final params = json['parameters'];
    return RuleAction(
      id: json['id']?.toString(),
      deviceId: json['deviceId']?.toString(),
      deviceName: json['deviceName']?.toString(),
      sceneId: json['sceneId']?.toString(),
      sceneName: json['sceneName']?.toString(),
      action: (json['action'] ?? '').toString(),
      parameters: params is Map ? Map<String, dynamic>.from(params) : const {},
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'deviceId': deviceId,
      if (sceneId != null) 'sceneId': sceneId,
      'action': action,
      'parameters': parameters,
      'order': order,
    };
  }
}

@immutable
class AutomationRule {
  const AutomationRule({
    required this.id,
    required this.homeId,
    required this.name,
    this.description,
    this.triggerType = 'SENSOR',
    this.enabled = true,
    this.conditions = const [],
    this.actions = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String homeId;
  final String name;
  final String? description;
  final String triggerType; // SENSOR, EVENT, SCHEDULE
  final bool enabled;
  final List<RuleCondition> conditions;
  final List<RuleAction> actions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    final rawConds = json['conditions'];
    final condList = (rawConds is List)
        ? rawConds
            .whereType<Map>()
            .map((c) => RuleCondition.fromJson(Map<String, dynamic>.from(c)))
            .toList()
        : const <RuleCondition>[];

    final rawActs = json['actions'];
    final actList = (rawActs is List)
        ? rawActs
            .whereType<Map>()
            .map((a) => RuleAction.fromJson(Map<String, dynamic>.from(a)))
            .toList()
        : const <RuleAction>[];

    return AutomationRule(
      id: (json['id'] ?? '').toString(),
      homeId: (json['homeId'] ?? '').toString(),
      name: (json['name'] ?? 'Quy tắc tự động').toString(),
      description: json['description']?.toString(),
      triggerType: (json['triggerType'] ?? 'SENSOR').toString(),
      enabled: json['enabled'] as bool? ?? true,
      conditions: condList,
      actions: actList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'triggerType': triggerType,
      'enabled': enabled,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  AutomationRule copyWith({
    String? id,
    String? homeId,
    String? name,
    String? description,
    String? triggerType,
    bool? enabled,
    List<RuleCondition>? conditions,
    List<RuleAction>? actions,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      description: description ?? this.description,
      triggerType: triggerType ?? this.triggerType,
      enabled: enabled ?? this.enabled,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class AutomationExecution {
  const AutomationExecution({
    required this.id,
    required this.ruleId,
    required this.status,
    required this.executedAt,
    this.durationMs,
    this.details,
  });

  final String id;
  final String ruleId;
  final String status;
  final DateTime executedAt;
  final int? durationMs;
  final String? details;

  factory AutomationExecution.fromJson(Map<String, dynamic> json) {
    return AutomationExecution(
      id: (json['id'] ?? '').toString(),
      ruleId: (json['ruleId'] ?? '').toString(),
      status: (json['status'] ?? 'SUCCESS').toString(),
      executedAt: json['executedAt'] != null
          ? DateTime.tryParse(json['executedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      details: json['details']?.toString(),
    );
  }
}
