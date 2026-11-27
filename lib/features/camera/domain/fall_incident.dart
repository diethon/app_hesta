import 'package:flutter/foundation.dart';

@immutable
class FallMetrics {
  const FallMetrics({
    this.vNorm = 0.0,
    this.accelG = 0.0,
    this.spineAngle = 0.0,
    this.motionEnergy = 0.0,
  });

  final double vNorm;
  final double accelG;
  final double spineAngle;
  final double motionEnergy;

  factory FallMetrics.fromJson(Map<String, dynamic> json) {
    return FallMetrics(
      vNorm: (json['v_norm'] as num?)?.toDouble() ?? 0.0,
      accelG: (json['accel_g'] as num?)?.toDouble() ?? 0.0,
      spineAngle: (json['spine_angle'] as num?)?.toDouble() ?? 0.0,
      motionEnergy: (json['motion_energy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class FallIncident {
  const FallIncident({
    required this.id,
    this.homeId,
    this.deviceId,
    this.roomName = 'Phòng Khách',
    this.incidentType = 'ACCIDENTAL_FALL',
    this.state = 'DETECTED',
    this.confidenceScore = 0.95,
    this.countdownRemainingSec = 30,
    this.detectedAt,
    this.metrics = const FallMetrics(),
    this.snapshotUrl,
  });

  final String id;
  final String? homeId;
  final String? deviceId;
  final String roomName;
  final String incidentType;
  final String state;
  final double confidenceScore;
  final int countdownRemainingSec;
  final String? detectedAt;
  final FallMetrics metrics;
  final String? snapshotUrl;

  bool get isActive =>
      state != 'FALSE_ALARM' && state != 'RESOLVED' && state != 'CANCELLED';

  bool get isEscalated => state == 'ESCALATED_SOS';

  String get localizedType {
    switch (incidentType) {
      case 'ACCIDENTAL_FALL':
        return 'Té Ngã Vô Ý (Accidental Fall)';
      case 'SAFE_ZONE_IMPACT_FALL':
        return 'Té Ngã Va Đập Vùng Nguy Hiểm';
      case 'HEAD_SLUMP_SUSPECTED':
        return 'Nghi Vấn Gục Đầu Bất Tỉnh';
      case 'FAINT_SYNCOPE':
        return 'Ngất Xỉu Đột Ngột (Syncope)';
      case 'BED_ROLL_OFF':
        return 'Lăn Rơi Khỏi Giường';
      default:
        return 'Phát Hiện Sự Cố Té Ngã';
    }
  }

  FallIncident copyWith({
    String? state,
    int? countdownRemainingSec,
    FallMetrics? metrics,
    String? snapshotUrl,
  }) {
    return FallIncident(
      id: id,
      homeId: homeId,
      deviceId: deviceId,
      roomName: roomName,
      incidentType: incidentType,
      state: state ?? this.state,
      confidenceScore: confidenceScore,
      countdownRemainingSec:
          countdownRemainingSec ?? this.countdownRemainingSec,
      detectedAt: detectedAt,
      metrics: metrics ?? this.metrics,
      snapshotUrl: snapshotUrl ?? this.snapshotUrl,
    );
  }

  factory FallIncident.fromJson(Map<String, dynamic> json) {
    return FallIncident(
      id: (json['id'] ?? '').toString(),
      homeId: json['homeId']?.toString(),
      deviceId: json['deviceId']?.toString(),
      roomName: (json['roomName'] ?? 'Camera Phòng Khách').toString(),
      incidentType: (json['incidentType'] ?? 'ACCIDENTAL_FALL').toString(),
      state: (json['state'] ?? 'DETECTED').toString(),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.95,
      countdownRemainingSec:
          (json['countdownRemainingSec'] as num?)?.toInt() ?? 30,
      detectedAt: json['detectedAt']?.toString(),
      metrics: json['metrics'] is Map<String, dynamic>
          ? FallMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : const FallMetrics(),
      snapshotUrl: json['snapshotUrl']?.toString(),
    );
  }
}

@immutable
class AiStatus {
  const AiStatus({
    this.isOnline = false,
    this.fps = 0,
    this.alert = false,
    this.state = 'STANDING',
    this.incidentType = 'NONE',
    this.metrics = const FallMetrics(),
  });

  final bool isOnline;
  final int fps;
  final bool alert;
  final String state;
  final String incidentType;
  final FallMetrics metrics;

  factory AiStatus.fromJson(Map<String, dynamic> json) {
    return AiStatus(
      isOnline: true,
      fps: (json['fps'] as num?)?.toInt() ?? 30,
      alert: json['alert'] == true,
      state: (json['state'] ?? 'STANDING').toString(),
      incidentType: (json['incident_type'] ?? 'NONE').toString(),
      metrics: json['metrics'] is Map<String, dynamic>
          ? FallMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : const FallMetrics(),
    );
  }
}

@immutable
class DemoVideoItem {
  const DemoVideoItem({
    required this.id,
    required this.name,
    required this.type,
    this.active = false,
  });

  final String id;
  final String name;
  final String type;
  final bool active;

  DemoVideoItem copyWith({bool? active}) {
    return DemoVideoItem(
      id: id,
      name: name,
      type: type,
      active: active ?? this.active,
    );
  }

  factory DemoVideoItem.fromJson(Map<String, dynamic> json) {
    return DemoVideoItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'LIVE').toString(),
      active: json['active'] == true,
    );
  }
}
