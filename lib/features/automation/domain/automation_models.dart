import 'package:flutter/foundation.dart';
import '../../../core/utils/time_format.dart';

@immutable
class RuleCondition {
  const RuleCondition({
    this.id,
    this.deviceId,
    this.deviceName,
    this.groupId,
    this.groupName,
    required this.attribute,
    required this.operator,
    required this.expectedValue,
    this.logicalOperator = 'AND',
    this.order = 0,
  });

  final String? id;
  final String? deviceId;
  final String? deviceName;
  /// Set instead of [deviceId]: true when ANY device of the group matches. '' = not picked yet.
  final String? groupId;
  final String? groupName;
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
      groupId: json['groupId']?.toString(),
      groupName: json['groupName']?.toString(),
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
      if (groupId != null) 'groupId': groupId,
      'attribute': attribute,
      'operator': operator,
      'expectedValue': expectedValue,
      'logicalOperator': logicalOperator,
      'order': order,
    };
  }

  RuleCondition copyWith({
    String? deviceId,
    bool clearDevice = false,
    String? groupId,
    String? groupName,
    bool clearGroup = false,
    String? attribute,
    String? operator,
    Object? expectedValue,
    String? logicalOperator,
    int? order,
  }) {
    return RuleCondition(
      id: id,
      deviceId: clearDevice ? null : (deviceId ?? this.deviceId),
      deviceName: clearDevice ? null : deviceName,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      groupName: clearGroup ? null : (groupName ?? this.groupName),
      attribute: attribute ?? this.attribute,
      operator: operator ?? this.operator,
      expectedValue: expectedValue ?? this.expectedValue,
      logicalOperator: logicalOperator ?? this.logicalOperator,
      order: order ?? this.order,
    );
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
    this.groupId,
    this.groupName,
    required this.action,
    this.parameters = const {},
    this.order = 0,
  });

  final String? id;
  final String? deviceId;
  final String? deviceName;
  final String? sceneId;
  final String? sceneName;
  /// Group step: every member that supports [action]. '' = not picked yet.
  final String? groupId;
  final String? groupName;
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
      groupId: json['groupId']?.toString(),
      groupName: json['groupName']?.toString(),
      action: (json['action'] ?? '').toString(),
      parameters: params is Map ? Map<String, dynamic>.from(params) : const {},
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  RuleAction copyWith({
    String? deviceId,
    String? deviceName,
    String? sceneId,
    String? sceneName,
    String? groupId,
    String? groupName,
    String? action,
    Map<String, dynamic>? parameters,
    int? order,
  }) {
    return RuleAction(
      id: id,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      sceneId: sceneId ?? this.sceneId,
      sceneName: sceneName ?? this.sceneName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      action: action ?? this.action,
      parameters: parameters ?? this.parameters,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'deviceId': deviceId,
      if (sceneId != null) 'sceneId': sceneId,
      if (groupId != null) 'groupId': groupId,
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
    this.holdSeconds = 0,
    this.schedules = const [],
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
  /// Run only when the conditions stay true this long (0 = at once).
  final int holdSeconds;
  /// Giờ chạy của quy tắc SCHEDULE (server gửi kèm để danh sách hiện "18:00 hằng ngày").
  final List<RuleSchedule> schedules;
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
      holdSeconds: (json['holdSeconds'] as num?)?.toInt() ?? 0,
      schedules: json['schedules'] is List
          ? (json['schedules'] as List).whereType<Map>().map((m) => RuleSchedule.fromJson(Map<String, dynamic>.from(m))).toList()
          : const [],
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
      'holdSeconds': holdSeconds,
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
    int? holdSeconds,
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
      holdSeconds: holdSeconds ?? this.holdSeconds,
      schedules: schedules,
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

  /// Backend AutomationExecutionResponse: matchedAt / startedAt / completedAt, test flag,
  /// resultDetail = [{deviceId|sceneId, action, success, status}]. Duration and the summary are derived.
  factory AutomationExecution.fromJson(Map<String, dynamic> json) {
    DateTime? at(String key) => json[key] != null
        ? DateTime.tryParse(json[key].toString())?.toLocal()
        : null;
    final started = at('startedAt');
    final completed = at('completedAt');
    final steps = json['resultDetail'] is List
        ? (json['resultDetail'] as List).whereType<Map>().toList()
        : const <Map>[];
    final failed = steps.where((d) => d['success'] != true).length;
    final summary = [
      if (json['test'] == true) 'Chạy thử',
      if (steps.isNotEmpty)
        failed == 0
            ? '${steps.length} hành động thành công'
            : '$failed/${steps.length} hành động lỗi',
    ].join(' · ');

    return AutomationExecution(
      id: (json['id'] ?? '').toString(),
      ruleId: (json['ruleId'] ?? '').toString(),
      status: (json['status'] ?? 'SUCCESS').toString(),
      executedAt: at('matchedAt') ?? started ?? DateTime.now(),
      durationMs: started != null && completed != null
          ? completed.difference(started).inMilliseconds
          : null,
      details: summary.isEmpty ? null : summary,
    );
  }
}

/// Một giờ chạy của quy tắc SCHEDULE (ScheduleResponse của backend).
@immutable
class RuleSchedule {
  const RuleSchedule({
    this.id,
    required this.time,
    this.repeatDays = const [],
    this.active = true,
  });

  /// null = chưa lưu.
  final String? id;

  /// "HH:mm:ss".
  final String time;

  /// ISO 1=T2 … 7=CN; rỗng = hằng ngày.
  final List<int> repeatDays;
  final bool active;

  factory RuleSchedule.fromJson(Map<String, dynamic> json) {
    final days = json['repeatDays'];
    return RuleSchedule(
      id: json['id']?.toString(),
      time: formatHms((json['scheduledTime'] ?? json['time'])?.toString()),
      repeatDays: days is List
          ? days.whereType<num>().map((n) => n.toInt()).toList()
          : const [],
      active: json['active'] as bool? ?? json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'scheduledTime': time,
    'repeatDays': [...repeatDays]..sort(),
    'active': active,
  };

  RuleSchedule copyWith({String? time, List<int>? repeatDays, bool? active}) =>
      RuleSchedule(
        id: id,
        time: time ?? this.time,
        repeatDays: repeatDays ?? this.repeatDays,
        active: active ?? this.active,
      );
}
