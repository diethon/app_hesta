import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/energy/data/energy_providers.dart';

void main() {
  test('parses summary, time series and breakdown from /energy', () {
    final report = EnergyReport.fromJson({
      'summary': {'totalKwh': 78.3, 'estimatedCostVnd': 162005},
      'timeSeries': [
        {'label': '13/11', 'kwh': 1.44},
        {'label': '14/11', 'kwh': 10},
      ],
      'breakdown': [
        {'deviceName': 'Điều hòa', 'kwh': 79.59, 'percentage': 57.9},
      ],
    });
    expect(report.totalKwh, 78.3);
    expect(report.costVnd, 162005);
    expect(report.points.map((p) => p.kwh), [1.44, 10.0]);
    expect(report.breakdown.single.name, 'Điều hòa');
    expect(report.breakdown.single.percentage, 57.9);
  });

  test('missing fields fall back to empty values', () {
    final report = EnergyReport.fromJson({});
    expect(report.totalKwh, 0);
    expect(report.points, isEmpty);
    expect(report.breakdown, isEmpty);
  });
}
