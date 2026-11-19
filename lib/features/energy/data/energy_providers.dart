import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../home/data/home_providers.dart';

/// One period of `/api/v1/homes/{homeId}/energy?period=...`.
class EnergyReport {
  const EnergyReport({
    required this.totalKwh,
    required this.costVnd,
    required this.points,
    required this.breakdown,
  });

  final double totalKwh;
  final int costVnd;
  final List<({String label, double kwh})> points;
  final List<({String name, double kwh, double percentage})> breakdown;

  factory EnergyReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map ? json['summary'] as Map : const {};
    double num0(Object? v) => v is num ? v.toDouble() : 0;
    return EnergyReport(
      totalKwh: num0(summary['totalKwh']),
      costVnd: num0(summary['estimatedCostVnd']).round(),
      points: [
        for (final p
            in (json['timeSeries'] as List? ?? const []).whereType<Map>())
          (label: '${p['label'] ?? ''}', kwh: num0(p['kwh'])),
      ],
      breakdown: [
        for (final d
            in (json['breakdown'] as List? ?? const []).whereType<Map>())
          (
            name: '${d['deviceName'] ?? ''}',
            kwh: num0(d['kwh']),
            percentage: num0(d['percentage']),
          ),
      ],
    );
  }
}

/// Keyed by the backend period code: `24H`, `7D` or `30D`.
final energyReportProvider = FutureProvider.autoDispose
    .family<EnergyReport?, String>((ref, period) async {
      final homeId = ref.watch(currentHomeIdProvider);
      if (homeId == null) return null;
      final response = await ref
          .watch(cloudApiClientProvider)
          .get<dynamic>(
            '/api/v1/homes/$homeId/energy',
            queryParameters: {'period': period},
          );
      final body = response.data;
      final result = body is Map ? (body['result'] ?? body) : null;
      return result is Map
          ? EnergyReport.fromJson(Map<String, dynamic>.from(result))
          : null;
    });
