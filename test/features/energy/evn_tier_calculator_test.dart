import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/energy/domain/evn_tier_calculator.dart';

void main() {
  group('EVN Tier Calculator Tests', () {
    test('0 kWh should be at Tier 1 with 0 VND cost', () {
      final result = computeEvnCostSplit(0);
      expect(result.computedTier, equals(1));
      expect(result.subtotalVnd, equals(0));
      expect(result.totalCostWithVatVnd, equals(0));
      expect(result.kwhLeftToNextTier, equals(50));
    });

    test('40 kWh should be within Tier 1 (1.893 VND/kWh)', () {
      final result = computeEvnCostSplit(40);
      expect(result.computedTier, equals(1));
      expect(result.subtotalVnd, equals(40 * 1893));
      expect(result.vatVnd, equals(40 * 1893 * 0.08));
      expect(result.kwhLeftToNextTier, equals(10));
    });

    test('80 kWh should span Tier 1 (50 kWh) and Tier 2 (30 kWh)', () {
      final result = computeEvnCostSplit(80);
      expect(result.computedTier, equals(2));
      final expectedSubtotal = (50 * 1893) + (30 * 1956);
      expect(result.subtotalVnd, equals(expectedSubtotal));
      expect(result.kwhLeftToNextTier, equals(20)); // 100 - 80 = 20
    });

    test('250 kWh should reach Tier 4', () {
      final result = computeEvnCostSplit(250);
      expect(result.computedTier, equals(4));
      final expectedSubtotal =
          (50 * 1893) + (50 * 1956) + (100 * 2271) + (50 * 2860);
      expect(result.subtotalVnd, equals(expectedSubtotal));
      expect(result.kwhLeftToNextTier, equals(50)); // 300 - 250 = 50
    });

    test('450 kWh should reach maximum Tier 6 with no next tier', () {
      final result = computeEvnCostSplit(450);
      expect(result.computedTier, equals(6));
      expect(result.kwhLeftToNextTier, isNull);
      expect(result.nextTierPrice, isNull);
      expect(result.progressInCurrentTier, equals(100));
    });

    test('formatVnd should format currency correctly with ₫ symbol', () {
      expect(formatVnd(0), contains('0'));
      expect(formatVnd(0), contains('₫'));
      expect(formatVnd(1250000), contains('1.250.000'));
      expect(formatVnd(1250000), contains('₫'));
    });

    test('formatKwh should format decimals properly', () {
      expect(formatKwh(24.5), equals('24,5'));
      expect(formatKwh(100), equals('100,0'));
    });
  });
}
