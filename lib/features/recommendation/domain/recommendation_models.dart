import 'package:flutter/foundation.dart';

@immutable
class RecommendationTrigger {
  const RecommendationTrigger({
    required this.type,
    this.time,
    this.repeatDays = const [],
    this.patternType,
  });

  final String type;
  final String? time;
  final List<int> repeatDays;
  final String? patternType;

  factory RecommendationTrigger.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['repeatDays'];
    final days = (daysRaw is List)
        ? daysRaw.whereType<num>().map((n) => n.toInt()).toList()
        : const <int>[];

    return RecommendationTrigger(
      type: (json['type'] ?? 'SCHEDULE').toString(),
      time: json['time']?.toString(),
      repeatDays: days,
      patternType: json['patternType']?.toString(),
    );
  }
}

@immutable
class RecommendationAction {
  const RecommendationAction({
    required this.deviceId,
    required this.action,
    this.parameters = const {},
  });

  final String deviceId;
  final String action;
  final Map<String, dynamic> parameters;

  factory RecommendationAction.fromJson(Map<String, dynamic> json) {
    final params = json['parameters'];
    return RecommendationAction(
      deviceId: (json['deviceId'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      parameters: params is Map ? Map<String, dynamic>.from(params) : const {},
    );
  }
}

@immutable
class Recommendation {
  const Recommendation({
    required this.id,
    required this.homeId,
    this.deviceId,
    this.deviceName,
    required this.triggerCondition,
    required this.proposedAction,
    required this.explanation,
    required this.confidence,
    required this.status, // PENDING, ACCEPTED, APPROVED, REJECTED, DISMISSED
    this.engineType = 'ML',
    this.modelVersion,
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String homeId;
  final String? deviceId;
  final String? deviceName;
  final RecommendationTrigger triggerCondition;
  final RecommendationAction proposedAction;
  final String explanation;
  final double confidence; // e.g. 0.85
  final String status;
  final String engineType;
  final String? modelVersion;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  int get confidencePercent => (confidence * 100).round();

  bool get isPending => status == 'PENDING';

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final triggerRaw = json['triggerCondition'];
    final actionRaw = json['proposedAction'];

    return Recommendation(
      id: (json['id'] ?? '').toString(),
      homeId: (json['homeId'] ?? '').toString(),
      deviceId: json['deviceId']?.toString(),
      deviceName: json['deviceName']?.toString(),
      triggerCondition: triggerRaw is Map
          ? RecommendationTrigger.fromJson(Map<String, dynamic>.from(triggerRaw))
          : const RecommendationTrigger(type: 'SCHEDULE'),
      proposedAction: actionRaw is Map
          ? RecommendationAction.fromJson(Map<String, dynamic>.from(actionRaw))
          : const RecommendationAction(deviceId: '', action: 'TURN_ON'),
      explanation: (json['explanation'] ?? 'Gợi ý hành vi tối ưu').toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      status: (json['status'] ?? 'PENDING').toString(),
      engineType: (json['engineType'] ?? 'ML').toString(),
      modelVersion: json['modelVersion']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
    );
  }

  Recommendation copyWith({
    String? status,
    DateTime? resolvedAt,
  }) {
    return Recommendation(
      id: id,
      homeId: homeId,
      deviceId: deviceId,
      deviceName: deviceName,
      triggerCondition: triggerCondition,
      proposedAction: proposedAction,
      explanation: explanation,
      confidence: confidence,
      status: status ?? this.status,
      engineType: engineType,
      modelVersion: modelVersion,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

@immutable
class MlModelStatus {
  const MlModelStatus({
    required this.status, // READY, COLD_START, NOT_TRAINED, TRAINING, UNAVAILABLE
    this.version = '1.0.0',
    this.modelType = 'LightGBM / BehaviorML',
    this.trainedAt,
    this.trainSamples,
    this.accuracy,
    this.precision,
    this.recall,
    this.f1Score,
    this.confidenceThreshold = 0.8,
  });

  final String status;
  final String version;
  final String modelType;
  final DateTime? trainedAt;
  final int? trainSamples;
  final double? accuracy;
  final double? precision;
  final double? recall;
  final double? f1Score;
  final double confidenceThreshold;

  bool get isReady => status.toUpperCase() == 'READY';
  bool get isColdStart => status.toUpperCase() == 'COLD_START';
  bool get isTraining => status.toUpperCase() == 'TRAINING';

  int get accuracyPercent =>
      accuracy != null ? (accuracy! * 100).round() : 88;

  factory MlModelStatus.fromJson(Map<String, dynamic> json) {
    return MlModelStatus(
      status: (json['status'] ?? 'READY').toString(),
      version: (json['version'] ?? '1.0.0').toString(),
      modelType: (json['modelType'] ?? 'BehaviorML').toString(),
      trainedAt: json['trainedAt'] != null
          ? DateTime.tryParse(json['trainedAt'].toString())
          : null,
      trainSamples: (json['trainSamples'] as num?)?.toInt(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      precision: (json['precision'] as num?)?.toDouble(),
      recall: (json['recall'] as num?)?.toDouble(),
      f1Score: (json['f1Score'] as num?)?.toDouble(),
      confidenceThreshold:
          (json['confidenceThreshold'] as num?)?.toDouble() ?? 0.8,
    );
  }
}
