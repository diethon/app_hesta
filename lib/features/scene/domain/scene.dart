import 'package:flutter/foundation.dart';

@immutable
class SceneAction {
  const SceneAction({
    required this.id,
    required this.targetDeviceId,
    required this.targetDeviceName,
    required this.action,
    required this.order,
    this.targetDeviceType,
    this.value,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String targetDeviceId;
  final String targetDeviceName;
  final String? targetDeviceType;
  final String action;
  final dynamic value;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SceneAction.fromJson(Map<String, dynamic> json) {
    return SceneAction(
      id: (json['id'] ?? '').toString(),
      targetDeviceId: (json['targetDeviceId'] ?? '').toString(),
      targetDeviceName: (json['targetDeviceName'] ?? 'Thiết bị').toString(),
      targetDeviceType: json['targetDeviceType']?.toString(),
      action: (json['action'] ?? '').toString(),
      value: json['value'],
      order: (json['order'] as num?)?.toInt() ?? 0,
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
      'targetDeviceId': targetDeviceId,
      'action': action,
      'value': value,
      'order': order,
    };
  }

  SceneAction copyWith({
    String? id,
    String? targetDeviceId,
    String? targetDeviceName,
    String? targetDeviceType,
    String? action,
    dynamic value,
    int? order,
  }) {
    return SceneAction(
      id: id ?? this.id,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      targetDeviceName: targetDeviceName ?? this.targetDeviceName,
      targetDeviceType: targetDeviceType ?? this.targetDeviceType,
      action: action ?? this.action,
      value: value ?? this.value,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@immutable
class Scene {
  const Scene({
    required this.id,
    required this.homeId,
    required this.name,
    this.icon,
    this.description,
    this.enabled = true,
    this.actions = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String homeId;
  final String name;
  final String? icon;
  final String? description;
  final bool enabled;
  final List<SceneAction> actions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Scene.fromJson(Map<String, dynamic> json) {
    final actionsRaw = json['actions'];
    final actionsList = (actionsRaw is List)
        ? actionsRaw
            .whereType<Map>()
            .map((a) => SceneAction.fromJson(Map<String, dynamic>.from(a)))
            .toList()
        : const <SceneAction>[];

    actionsList.sort((a, b) => a.order.compareTo(b.order));

    return Scene(
      id: (json['id'] ?? '').toString(),
      homeId: (json['homeId'] ?? '').toString(),
      name: (json['name'] ?? 'Kịch bản').toString(),
      icon: json['icon']?.toString(),
      description: json['description']?.toString(),
      enabled: json['enabled'] as bool? ?? true,
      actions: actionsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
      'enabled': enabled,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
      'enabled': enabled,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  Scene copyWith({
    String? id,
    String? homeId,
    String? name,
    String? icon,
    String? description,
    bool? enabled,
    List<SceneAction>? actions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Scene(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class SceneExecutionDetail {
  const SceneExecutionDetail({
    required this.deviceId,
    required this.action,
    required this.success,
    required this.status,
    this.message,
  });

  final String deviceId;
  final String action;
  final bool success;
  final String status;
  final String? message;

  factory SceneExecutionDetail.fromJson(Map<String, dynamic> json) {
    return SceneExecutionDetail(
      deviceId: (json['deviceId'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      success: json['success'] as bool? ?? false,
      status: (json['status'] ?? '').toString(),
      message: json['message']?.toString(),
    );
  }
}

@immutable
class SceneExecution {
  const SceneExecution({
    required this.id,
    required this.sceneId,
    required this.triggerSource,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.resultDetail = const [],
  });

  final String id;
  final String sceneId;
  final String triggerSource;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<SceneExecutionDetail> resultDetail;

  factory SceneExecution.fromJson(Map<String, dynamic> json) {
    final detailsRaw = json['resultDetail'];
    final details = (detailsRaw is List)
        ? detailsRaw
            .whereType<Map>()
            .map((d) => SceneExecutionDetail.fromJson(Map<String, dynamic>.from(d)))
            .toList()
        : const <SceneExecutionDetail>[];

    return SceneExecution(
      id: (json['id'] ?? '').toString(),
      sceneId: (json['sceneId'] ?? '').toString(),
      triggerSource: (json['triggerSource'] ?? 'MANUAL').toString(),
      status: (json['status'] ?? 'SUCCESS').toString(),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      resultDetail: details,
    );
  }
}

@immutable
class SceneSchedule {
  const SceneSchedule({
    required this.id,
    required this.sceneId,
    required this.time,
    required this.repeatDays,
    required this.enabled,
  });

  final String id;
  final String sceneId;
  final String time;
  final List<int> repeatDays;
  final bool enabled;

  factory SceneSchedule.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['repeatDays'];
    final days = (daysRaw is List)
        ? daysRaw.whereType<num>().map((n) => n.toInt()).toList()
        : const <int>[];

    return SceneSchedule(
      id: (json['id'] ?? '').toString(),
      sceneId: (json['sceneId'] ?? '').toString(),
      time: (json['time'] ?? '07:00').toString(),
      repeatDays: days,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'repeatDays': repeatDays,
      'enabled': enabled,
    };
  }
}
