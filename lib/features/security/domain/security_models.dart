/// Mirrors backend `DeviceAnomalyResponse` and `SecurityEventResponse`.
class DeviceAnomaly {
  const DeviceAnomaly({
    required this.id,
    required this.anomalyType,
    required this.status,
    required this.detectedAt,
    this.deviceId,
    this.deviceName,
    this.roomName,
    this.currentValue,
    this.expectedRange,
    this.severity,
    this.reason,
    this.occurrenceCount,
  });

  factory DeviceAnomaly.fromJson(Map<String, dynamic> json) => DeviceAnomaly(
    id: json['id'].toString(),
    anomalyType: json['anomalyType']?.toString() ?? '',
    status: json['status']?.toString() ?? 'OPEN',
    detectedAt: parseDate(json['detectedAt']),
    deviceId: json['deviceId']?.toString(),
    deviceName: json['deviceName'] as String?,
    roomName: json['roomName'] as String?,
    currentValue: json['currentValue']?.toString(),
    expectedRange: json['expectedRange']?.toString(),
    severity: json['severity']?.toString(),
    reason: json['reason'] as String?,
    occurrenceCount: (json['occurrenceCount'] as num?)?.toInt(),
  );

  final String id;
  final String anomalyType;
  final String status;
  final DateTime detectedAt;
  final String? deviceId;
  final String? deviceName;
  final String? roomName;
  final String? currentValue;
  final String? expectedRange;
  final String? severity;
  final String? reason;
  final int? occurrenceCount;

  String get title => anomalyTitles[anomalyType] ?? anomalyType;
}

class SecurityEvent {
  const SecurityEvent({
    required this.id,
    required this.eventType,
    required this.status,
    required this.detectedAt,
    this.deviceName,
    this.roomName,
    this.location,
    this.severity,
  });

  factory SecurityEvent.fromJson(Map<String, dynamic> json) => SecurityEvent(
    id: json['id'].toString(),
    eventType: json['eventType']?.toString() ?? '',
    status: json['status']?.toString() ?? 'DETECTED',
    detectedAt: parseDate(json['detectedAt']),
    deviceName: json['deviceName'] as String?,
    roomName: json['roomName'] as String?,
    location: json['location'] as String?,
    severity: json['severity']?.toString(),
  );

  final String id;
  final String eventType;
  final String status;
  final DateTime detectedAt;
  final String? deviceName;
  final String? roomName;
  final String? location;
  final String? severity;

  String get title =>
      eventType == 'INTRUSION' ? 'Phát hiện xâm nhập' : 'Phát hiện chuyển động';
}

DateTime parseDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();

const anomalyTitles = <String, String>{
  'GAS_LEAKAGE': 'Rò rỉ khí gas',
  'SMOKE_DETECTED': 'Phát hiện khói',
  'HIGH_TEMPERATURE': 'Nhiệt độ cao bất thường',
  'SENSOR_OFFLINE': 'Cảm biến mất kết nối',
};

const anomalyStatusLabels = <String, String>{
  'OPEN': 'Đang mở',
  'ACKNOWLEDGED': 'Đã xác nhận',
  'RESOLVED': 'Đã xử lý',
};

const eventStatusLabels = <String, String>{
  'DETECTED': 'Chưa xử lý',
  'CONFIRMED': 'Đã xác nhận',
  'DISMISSED': 'Báo động giả',
};

const severityLabels = <String, String>{
  'LOW': 'Thấp',
  'MEDIUM': 'Trung bình',
  'HIGH': 'Cao',
  'CRITICAL': 'Nghiêm trọng',
};
