import 'package:intl/intl.dart';

class EvnTierDefinition {
  const EvnTierDefinition({
    required this.tier,
    required this.label,
    required this.rangeLabel,
    required this.minKwh,
    required this.maxKwh,
    required this.capacityKwh,
    required this.pricePerKwh,
  });

  final int tier;
  final String label;
  final String rangeLabel;
  final double minKwh;
  final double maxKwh;
  final double capacityKwh;
  final double pricePerKwh;
}

const List<EvnTierDefinition> evnTiers = [
  EvnTierDefinition(
    tier: 1,
    label: 'Bậc 1',
    rangeLabel: '0 – 50 kWh',
    minKwh: 0,
    maxKwh: 50,
    capacityKwh: 50,
    pricePerKwh: 1893,
  ),
  EvnTierDefinition(
    tier: 2,
    label: 'Bậc 2',
    rangeLabel: '51 – 100 kWh',
    minKwh: 50,
    maxKwh: 100,
    capacityKwh: 50,
    pricePerKwh: 1956,
  ),
  EvnTierDefinition(
    tier: 3,
    label: 'Bậc 3',
    rangeLabel: '101 – 200 kWh',
    minKwh: 100,
    maxKwh: 200,
    capacityKwh: 100,
    pricePerKwh: 2271,
  ),
  EvnTierDefinition(
    tier: 4,
    label: 'Bậc 4',
    rangeLabel: '201 – 300 kWh',
    minKwh: 200,
    maxKwh: 300,
    capacityKwh: 100,
    pricePerKwh: 2860,
  ),
  EvnTierDefinition(
    tier: 5,
    label: 'Bậc 5',
    rangeLabel: '301 – 400 kWh',
    minKwh: 300,
    maxKwh: 400,
    capacityKwh: 100,
    pricePerKwh: 3197,
  ),
  EvnTierDefinition(
    tier: 6,
    label: 'Bậc 6',
    rangeLabel: '> 400 kWh',
    minKwh: 400,
    maxKwh: double.infinity,
    capacityKwh: double.infinity,
    pricePerKwh: 3302,
  ),
];

const double vatRate = 0.08;

class TierCostItem {
  const TierCostItem({
    required this.tier,
    required this.label,
    required this.rangeLabel,
    required this.pricePerKwh,
    required this.kwhInTier,
    required this.costVnd,
    required this.isActive,
    required this.isFilled,
  });

  final int tier;
  final String label;
  final String rangeLabel;
  final double pricePerKwh;
  final double kwhInTier;
  final double costVnd;
  final bool isActive;
  final bool isFilled;
}

class EvnCostSplitResult {
  const EvnCostSplitResult({
    required this.computedTier,
    required this.tierCosts,
    required this.subtotalVnd,
    required this.vatVnd,
    required this.totalCostWithVatVnd,
    required this.progressInCurrentTier,
    required this.kwhLeftToNextTier,
    required this.nextTierPrice,
  });

  final int computedTier;
  final List<TierCostItem> tierCosts;
  final double subtotalVnd;
  final double vatVnd;
  final double totalCostWithVatVnd;
  final double progressInCurrentTier;
  final double? kwhLeftToNextTier;
  final double? nextTierPrice;
}

EvnCostSplitResult computeEvnCostSplit(double totalKwh, [int? currentTierOverride]) {
  double remaining = totalKwh.clamp(0, double.infinity);
  double subtotal = 0;
  final tierCosts = <TierCostItem>[];
  int activeTier = 1;

  for (final tierDef in evnTiers) {
    if (remaining <= 0 && tierCosts.isNotEmpty) {
      tierCosts.add(
        TierCostItem(
          tier: tierDef.tier,
          label: tierDef.label,
          rangeLabel: tierDef.rangeLabel,
          pricePerKwh: tierDef.pricePerKwh,
          kwhInTier: 0,
          costVnd: 0,
          isActive: false,
          isFilled: false,
        ),
      );
      continue;
    }

    final kwhInTier = remaining.clamp(0, tierDef.capacityKwh).toDouble();
    final cost = kwhInTier * tierDef.pricePerKwh;
    subtotal += cost;

    final isFilled = kwhInTier >= tierDef.capacityKwh && tierDef.capacityKwh.isFinite;
    final isActive = kwhInTier > 0 || tierDef.tier == 1;

    if (kwhInTier > 0) {
      activeTier = tierDef.tier;
    }

    tierCosts.add(
      TierCostItem(
        tier: tierDef.tier,
        label: tierDef.label,
        rangeLabel: tierDef.rangeLabel,
        pricePerKwh: tierDef.pricePerKwh,
        kwhInTier: kwhInTier,
        costVnd: cost,
        isActive: isActive,
        isFilled: isFilled,
      ),
    );

    remaining -= kwhInTier;
  }

  final finalTier = currentTierOverride ?? activeTier;
  final activeDef = evnTiers.firstWhere(
    (t) => t.tier == finalTier,
    orElse: () => evnTiers.first,
  );

  double progressInTier = 0;
  double? kwhLeft;
  double? nextPrice;

  if (activeDef.capacityKwh.isFinite) {
    final kwhInThisTier = (totalKwh - activeDef.minKwh).clamp(0, activeDef.capacityKwh).toDouble();
    progressInTier = ((kwhInThisTier / activeDef.capacityKwh) * 100).clamp(0, 100);
    kwhLeft = (activeDef.capacityKwh - kwhInThisTier).clamp(0, double.infinity);
    if (finalTier < 6) {
      nextPrice = evnTiers[finalTier].pricePerKwh;
    }
  } else {
    progressInTier = 100;
    kwhLeft = null;
    nextPrice = null;
  }

  final vat = subtotal * vatRate;
  final totalWithVat = subtotal + vat;

  return EvnCostSplitResult(
    computedTier: finalTier,
    tierCosts: tierCosts,
    subtotalVnd: subtotal,
    vatVnd: vat,
    totalCostWithVatVnd: totalWithVat,
    progressInCurrentTier: progressInTier,
    kwhLeftToNextTier: kwhLeft,
    nextTierPrice: nextPrice,
  );
}

String formatVnd(num? amount) {
  if (amount == null || amount.isNaN) return '0 ₫';
  final formatter = NumberFormat('#,###', 'vi_VN');
  return '${formatter.format(amount.round())} ₫';
}

String formatKwh(num? kwh, [int decimals = 1]) {
  if (kwh == null || kwh.isNaN) return '0';
  final formatter = NumberFormat.decimalPatternDigits(
    locale: 'vi_VN',
    decimalDigits: decimals,
  );
  return formatter.format(kwh);
}
