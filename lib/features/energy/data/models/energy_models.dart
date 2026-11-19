class EnergySummaryModel {
  const EnergySummaryModel({
    required this.totalKwh,
    required this.estimatedCostVnd,
    required this.currentTier,
    required this.projectedMonthKwh,
    required this.projectedMonthCostVnd,
    required this.comparisonLastPeriodPercent,
    required this.period,
    required this.activeDeviceCount,
    required this.totalDeviceCount,
  });

  final double totalKwh;
  final double estimatedCostVnd;
  final int currentTier;
  final double projectedMonthKwh;
  final double projectedMonthCostVnd;
  final double comparisonLastPeriodPercent;
  final String period;
  final int activeDeviceCount;
  final int totalDeviceCount;

  factory EnergySummaryModel.fromJson(Map<String, dynamic> json) {
    return EnergySummaryModel(
      totalKwh: (json['totalKwh'] as num?)?.toDouble() ?? 0.0,
      estimatedCostVnd: (json['estimatedCostVnd'] as num?)?.toDouble() ?? 0.0,
      currentTier: (json['currentTier'] as num?)?.toInt() ?? 1,
      projectedMonthKwh: (json['projectedMonthKwh'] as num?)?.toDouble() ?? 0.0,
      projectedMonthCostVnd:
          (json['projectedMonthCostVnd'] as num?)?.toDouble() ?? 0.0,
      comparisonLastPeriodPercent:
          (json['comparisonLastPeriodPercent'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as String? ?? '30D',
      activeDeviceCount: (json['activeDeviceCount'] as num?)?.toInt() ?? 0,
      totalDeviceCount: (json['totalDeviceCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalKwh': totalKwh,
    'estimatedCostVnd': estimatedCostVnd,
    'currentTier': currentTier,
    'projectedMonthKwh': projectedMonthKwh,
    'projectedMonthCostVnd': projectedMonthCostVnd,
    'comparisonLastPeriodPercent': comparisonLastPeriodPercent,
    'period': period,
    'activeDeviceCount': activeDeviceCount,
    'totalDeviceCount': totalDeviceCount,
  };
}

class EnergyTimeSeriesPointModel {
  const EnergyTimeSeriesPointModel({
    required this.timestamp,
    required this.label,
    required this.kwh,
    required this.costVnd,
  });

  final String timestamp;
  final String label;
  final double kwh;
  final double costVnd;

  factory EnergyTimeSeriesPointModel.fromJson(Map<String, dynamic> json) {
    return EnergyTimeSeriesPointModel(
      timestamp: json['timestamp'] as String? ?? '',
      label: json['label'] as String? ?? '',
      kwh: (json['kwh'] as num?)?.toDouble() ?? 0.0,
      costVnd: (json['costVnd'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'label': label,
    'kwh': kwh,
    'costVnd': costVnd,
  };
}

class DeviceEnergyBreakdownModel {
  const DeviceEnergyBreakdownModel({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.roomName,
    required this.kwh,
    required this.percentage,
    required this.costVnd,
    required this.totalOnHours,
    required this.wattage,
  });

  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String roomName;
  final double kwh;
  final double percentage;
  final double costVnd;
  final double totalOnHours;
  final double wattage;

  factory DeviceEnergyBreakdownModel.fromJson(Map<String, dynamic> json) {
    return DeviceEnergyBreakdownModel(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? 'OTHER',
      roomName: json['roomName'] as String? ?? '',
      kwh: (json['kwh'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      costVnd: (json['costVnd'] as num?)?.toDouble() ?? 0.0,
      totalOnHours: (json['totalOnHours'] as num?)?.toDouble() ?? 0.0,
      wattage: (json['wattage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'deviceType': deviceType,
    'roomName': roomName,
    'kwh': kwh,
    'percentage': percentage,
    'costVnd': costVnd,
    'totalOnHours': totalOnHours,
    'wattage': wattage,
  };
}

class EnergyAnalyticsModel {
  const EnergyAnalyticsModel({
    required this.summary,
    required this.timeSeries,
    required this.breakdown,
  });

  final EnergySummaryModel summary;
  final List<EnergyTimeSeriesPointModel> timeSeries;
  final List<DeviceEnergyBreakdownModel> breakdown;

  factory EnergyAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final summaryData = json['summary'] as Map<String, dynamic>? ?? {};
    final timeSeriesList =
        (json['timeSeries'] as List<dynamic>?)
            ?.map(
              (e) => EnergyTimeSeriesPointModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList() ??
        [];
    final breakdownList =
        (json['breakdown'] as List<dynamic>?)
            ?.map(
              (e) => DeviceEnergyBreakdownModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList() ??
        [];

    return EnergyAnalyticsModel(
      summary: EnergySummaryModel.fromJson(summaryData),
      timeSeries: timeSeriesList,
      breakdown: breakdownList,
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary.toJson(),
    'timeSeries': timeSeries.map((e) => e.toJson()).toList(),
    'breakdown': breakdown.map((e) => e.toJson()).toList(),
  };
}
