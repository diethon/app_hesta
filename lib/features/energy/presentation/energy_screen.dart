import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../home/data/home_providers.dart';
import '../data/energy_providers.dart';
import '../data/models/energy_models.dart';
import '../domain/evn_tier_calculator.dart';

class EnergyScreen extends ConsumerStatefulWidget {
  const EnergyScreen({super.key});

  @override
  ConsumerState<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends ConsumerState<EnergyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barAnimCtrl;
  late final Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _barAnim = CurvedAnimation(parent: _barAnimCtrl, curve: GlassTokens.curve);
    _barAnimCtrl.forward();
  }

  @override
  void dispose() {
    _barAnimCtrl.dispose();
    super.dispose();
  }

  int _periodToIndex(String period) {
    switch (period) {
      case '24H':
        return 0;
      case '7D':
        return 1;
      case '30D':
      default:
        return 2;
    }
  }

  String _indexToPeriod(int index) {
    switch (index) {
      case 0:
        return '24H';
      case 1:
        return '7D';
      case 2:
      default:
        return '30D';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    final selectedPeriod = ref.watch(selectedEnergyPeriodProvider);
    final analyticsAsync = ref.watch(energyAnalyticsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 68,
            flexibleSpace: GlassAppBar(
              centerTitle: false,
              title: l10n.appName,
              actions: [
                GlassIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Làm mới',
                  onTap: () {
                    ref.invalidate(energyAnalyticsProvider);
                    _barAnimCtrl
                      ..reset()
                      ..forward();
                  },
                ),
                GlassIconButton(
                  icon: Icons.notifications_outlined,
                  tooltip: l10n.notifications,
                  onTap: () => context.go('/profile/notifications'),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.navClearance,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: AppColors.auroraWarning.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.auroraWarning.withValues(
                            alpha: 0.28,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.auroraWarning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiêu Thụ Năng Lượng',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ước tính kWh & Tiền điện biểu giá EVN 6 bậc',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Period Selector (24H, 7D, 30D)
                GlassSegmentedControl(
                  segments: const [
                    GlassSegment(label: '24 Giờ'),
                    GlassSegment(label: '7 Ngày'),
                    GlassSegment(label: '30 Ngày'),
                  ],
                  selectedIndex: _periodToIndex(selectedPeriod),
                  onChanged: (index) {
                    ref.read(selectedEnergyPeriodProvider.notifier).state =
                        _indexToPeriod(index);
                    _barAnimCtrl
                      ..reset()
                      ..forward();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                analyticsAsync.when(
                  loading: () => const _LoadingEnergySection(),
                  error: (err, _) => _ErrorEnergySection(
                    error: err.toString(),
                    onRetry: () => ref.invalidate(energyAnalyticsProvider),
                  ),
                  data: (data) => _EnergyDataSection(
                    data: data,
                    barAnim: _barAnim,
                    mint: mint,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Main Data View
// ─────────────────────────────────────────────────────────────────────
class _EnergyDataSection extends StatelessWidget {
  const _EnergyDataSection({
    required this.data,
    required this.barAnim,
    required this.mint,
  });

  final EnergyAnalyticsModel data;
  final Animation<double> barAnim;
  final Color mint;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;

    final split = computeEvnCostSplit(summary.totalKwh, summary.currentTier);
    final comparisonPercent = summary.comparisonLastPeriodPercent;
    final isReduced = comparisonPercent <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── TOP KPI CARDS ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.auroraWarning,
                label: 'Tổng Điện Năng',
                value: formatKwh(summary.totalKwh),
                unit: 'kWh',
                badgeText: comparisonPercent != 0
                    ? '${isReduced ? '▼' : '▲'} ${comparisonPercent.abs().toStringAsFixed(1)}%'
                    : null,
                isBadgePositive: isReduced,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _KpiCard(
                icon: Icons.payments_outlined,
                iconColor: mint,
                label: 'Tiền Tạm Tính',
                value: formatVnd(summary.estimatedCostVnd),
                unit: '',
                badgeText: 'Đã gồm VAT 8%',
                isBadgePositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── EVN TIER LADDER CARD ──────────────────────────────────────
        _EvnTierLadderCard(totalKwh: summary.totalKwh, split: split),
        const SizedBox(height: AppSpacing.md),

        // ── 24H/7D/30D TREND CHART CARD ──────────────────────────────
        _EnergyChartCard(timeSeries: data.timeSeries, period: summary.period),
        const SizedBox(height: AppSpacing.md),

        // ── TOP CONSUMING DEVICES BREAKDOWN ──────────────────────────
        _TopConsumersBreakdownCard(
          breakdown: data.breakdown,
          animation: barAnim,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── DEMAND RESPONSE & PEAK SHAVING (UC-ENG-03) ────────────────
        const _DemandResponseSection(),
        const SizedBox(height: AppSpacing.md),

        // ── EFFICIENCY TIP & PEAK SHAVING ────────────────────────────
        _EnergySavingsTipCard(currentTier: split.computedTier, mint: mint),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// KPI Card
// ─────────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    this.badgeText,
    this.isBadgePositive = true,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String? badgeText;
  final bool isBadgePositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final danger = isDark ? AppColors.auroraError : AppColors.error;
    final badgeColor = isBadgePositive ? mint : danger;

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// EVN Tier Ladder Card (Bậc 1 - Bậc 6)
// ─────────────────────────────────────────────────────────────────────
class _EvnTierLadderCard extends StatefulWidget {
  const _EvnTierLadderCard({required this.totalKwh, required this.split});

  final double totalKwh;
  final EvnCostSplitResult split;

  @override
  State<_EvnTierLadderCard> createState() => _EvnTierLadderCardState();
}

class _EvnTierLadderCardState extends State<_EvnTierLadderCard> {
  bool _expanded = false;

  Color _getTierColor(int tier, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final danger = isDark ? AppColors.auroraError : AppColors.error;
    switch (tier) {
      case 1:
      case 2:
        return mint;
      case 3:
      case 4:
        return AppColors.auroraWarning;
      case 5:
      case 6:
      default:
        return danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final split = widget.split;
    final currentTier = split.computedTier;
    final tierColor = _getTierColor(currentTier, theme.brightness);

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    ),
                    child: Icon(Icons.layers_rounded, color: accent, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Biểu Giá EVN 6 Bậc',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.14),
                  border: Border.all(color: tierColor.withValues(alpha: 0.45)),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Bậc $currentTier',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Current tier progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mức tích lũy: ${formatKwh(widget.totalKwh)} kWh',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currentTier == 6
                    ? '100% (Bậc kịch trần)'
                    : '${split.progressInCurrentTier.toStringAsFixed(0)}% bậc hiện tại',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: split.progressInCurrentTier / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),

          // Guidance box
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: tierColor.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Icon(
                  currentTier == 6
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  color: tierColor,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    currentTier == 6
                        ? 'Đang ở bậc giá cao nhất (>400 kWh: 3.302 đ/kWh). Hãy kích hoạt kịch bản ngắt tải đỉnh.'
                        : 'Còn ${formatKwh(split.kwhLeftToNextTier)} kWh nữa sẽ chuyển lên Bậc ${currentTier + 1} (${formatVnd(split.nextTierPrice)}/kWh).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: tierColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Expandable detail button
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded
                        ? 'Thu gọn bảng giá'
                        : 'Xem chi tiết 6 bậc tính giá',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: accent,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            Divider(
              height: AppSpacing.lg,
              color: GlassTokens.borderSolid(theme.brightness),
            ),
            ...split.tierCosts.map((tier) {
              final isCurrent = tier.tier == currentTier;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? tierColor.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        tier.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isCurrent ? tierColor : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${tier.rangeLabel} (${tier.pricePerKwh.round()} đ)',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${formatKwh(tier.kwhInTier)} kWh',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 72,
                      child: Text(
                        formatVnd(tier.costVnd),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isCurrent ? tierColor : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thuế GTGT (VAT 8%):',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
                Text(
                  formatVnd(split.vatVnd),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Interactive Energy Chart Card
// ─────────────────────────────────────────────────────────────────────
class _EnergyChartCard extends StatelessWidget {
  const _EnergyChartCard({required this.timeSeries, required this.period});

  final List<EnergyTimeSeriesPointModel> timeSeries;
  final String period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    EnergyTimeSeriesPointModel? peak;
    if (timeSeries.isNotEmpty) {
      peak = timeSeries.reduce((a, b) => a.kwh > b.kwh ? a : b);
    }

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biểu Đồ Phụ Tải ($period)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (peak != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.auroraWarning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Đỉnh: ${formatKwh(peak.kwh)} kWh',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.auroraWarning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: timeSeries.isEmpty
                ? const Center(child: Text('Không có dữ liệu chuỗi thời gian'))
                : CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _TimeSeriesChartPainter(
                      points: timeSeries,
                      lineColor: accent,
                      gridColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      peakColor: AppColors.auroraWarning,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: (timeSeries.length <= 7
                    ? timeSeries
                    : [
                        for (int i = 0; i < 6; i++)
                          timeSeries[((i * (timeSeries.length - 1)) / 5).round()],
                      ])
                .map(
                  (pt) => Text(
                    pt.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TimeSeriesChartPainter extends CustomPainter {
  _TimeSeriesChartPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.peakColor,
  });

  final List<EnergyTimeSeriesPointModel> points;
  final Color lineColor;
  final Color gridColor;
  final Color peakColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final yRatio in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, h * yRatio), Offset(w, h * yRatio), gridPaint);
    }

    final maxVal = points
        .map((e) => e.kwh)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    final n = points.length;
    final pixelPoints = <Offset>[];

    for (var i = 0; i < n; i++) {
      final x = n == 1 ? w / 2 : (i / (n - 1)) * w;
      final y = h - (points[i].kwh / (maxVal * 1.15)) * h;
      pixelPoints.add(Offset(x, y.clamp(10.0, h - 5.0)));
    }

    final path = Path()..moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
    for (var i = 1; i < pixelPoints.length; i++) {
      final p0 = pixelPoints[i - 1];
      final p1 = pixelPoints[i];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    final areaPath = Path.from(path)
      ..lineTo(pixelPoints.last.dx, h)
      ..lineTo(pixelPoints.first.dx, h)
      ..close();

    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(areaPath, gradPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    int peakIndex = 0;
    double highestKwh = 0;
    for (var i = 0; i < points.length; i++) {
      if (points[i].kwh > highestKwh) {
        highestKwh = points[i].kwh;
        peakIndex = i;
      }
    }
    final peakPoint = pixelPoints[peakIndex];
    canvas.drawCircle(peakPoint, 5, Paint()..color = peakColor);
    canvas.drawCircle(peakPoint, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_TimeSeriesChartPainter old) =>
      old.points != points ||
      old.lineColor != lineColor ||
      old.gridColor != gridColor ||
      old.peakColor != peakColor;
}

// ─────────────────────────────────────────────────────────────────────
// Top Consumers Breakdown Card
// ─────────────────────────────────────────────────────────────────────
class _TopConsumersBreakdownCard extends StatelessWidget {
  const _TopConsumersBreakdownCard({
    required this.breakdown,
    required this.animation,
  });

  final List<DeviceEnergyBreakdownModel> breakdown;
  final Animation<double> animation;

  IconData _getDeviceIcon(String type) {
    switch (type.toUpperCase()) {
      case 'AIR_CONDITIONER':
      case 'CLIMATE':
        return Icons.ac_unit_rounded;
      case 'WATER_HEATER':
        return Icons.water_drop_rounded;
      case 'REFRIGERATOR':
        return Icons.kitchen_rounded;
      case 'LIGHT':
      case 'LIGHTING':
        return Icons.lightbulb_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  Color _getCategoryColor(int index, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final danger = isDark ? AppColors.auroraError : AppColors.error;
    final colors = [
      AppColors.auroraWarning,
      theme.colorScheme.primary,
      mint,
      AppColors.orbViolet,
      danger,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cơ Cấu Tiêu Thụ Thiết Bị',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${breakdown.length} thiết bị',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...breakdown.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final color = _getCategoryColor(idx, theme);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                        ),
                        child: Icon(
                          _getDeviceIcon(item.deviceType),
                          color: color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.deviceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.roomName} • ${item.wattage.round()}W',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${formatKwh(item.kwh)} kWh',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          Text(
                            formatVnd(item.costVnd),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: (item.percentage / 100) * animation.value,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.06,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Demand Response & Peak Shaving Card (UC-ENG-03)
// ─────────────────────────────────────────────────────────────────────
class _DemandResponseSection extends ConsumerStatefulWidget {
  const _DemandResponseSection();

  @override
  ConsumerState<_DemandResponseSection> createState() =>
      _DemandResponseSectionState();
}

class _DemandResponseSectionState
    extends ConsumerState<_DemandResponseSection> {
  bool _initialized = false;
  bool _enabled = true;
  double _thresholdWatts = 4000;
  String _mode = 'AUTO_SHED';
  bool _isSaving = false;
  bool _isEvaluating = false;
  DemandResponseEvaluationModel? _evaluation;

  void _syncFromSettings(DemandResponseSettingsModel? settings) {
    if (_initialized || settings == null) {
      return;
    }
    _initialized = true;
    _enabled = settings.enabled;
    _thresholdWatts = settings.peakThresholdWatts.clamp(1500.0, 8000.0);
    _mode = settings.mode == 'ALERT_ONLY' ? 'ALERT_ONLY' : 'AUTO_SHED';
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final homeId = ref.read(currentHomeIdProvider);
      final updated = await ref
          .read(energyRepositoryProvider)
          .updateDemandResponseSettings(
            homeId: homeId,
            settings: DemandResponseSettingsModel(
              homeId: homeId,
              enabled: _enabled,
              peakThresholdWatts: _thresholdWatts,
              mode: _mode,
            ),
          );
      ref.invalidate(demandResponseSettingsProvider);
      if (mounted) {
        setState(() {
          _enabled = updated.enabled;
          _thresholdWatts = updated.peakThresholdWatts.clamp(1500.0, 8000.0);
          _mode = updated.mode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraMintOnLight,
            content: Text(
              'Đã lưu ngưỡng cắt tải: ${(_thresholdWatts / 1000).toStringAsFixed(1)} kW (${_mode == 'AUTO_SHED' ? 'Tự động ngắt' : 'Chỉ cảnh báo'})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraError,
            content: Text('Không thể lưu cấu hình cắt tải: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _evaluatePeak({double? simulatedWatts}) async {
    setState(() => _isEvaluating = true);
    try {
      final homeId = ref.read(currentHomeIdProvider);
      final res = await ref
          .read(energyRepositoryProvider)
          .evaluateDemandResponse(
            homeId: homeId,
            simulatedWatts: simulatedWatts,
          );
      if (mounted) {
        setState(() => _evaluation = res);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: res.status == 'PEAK_SHEDDING_EXECUTED'
                ? AppColors.auroraWarning
                : AppColors.auroraMintOnLight,
            content: Text(
              res.message.isNotEmpty
                  ? res.message
                  : 'Đánh giá phụ tải: ${res.totalCurrentWatts.round()}W',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraError,
            content: Text('Lỗi đánh giá phụ tải: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEvaluating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final danger = isDark ? AppColors.auroraError : AppColors.error;
    final settingsAsync = ref.watch(demandResponseSettingsProvider);
    _syncFromSettings(settingsAsync.valueOrNull);

    final isOverload =
        _evaluation != null && _evaluation!.totalCurrentWatts > _thresholdWatts;

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.auroraWarning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: AppColors.auroraWarning,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cắt Tải Đỉnh (Peak Shaving)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Bảo vệ quá tải theo 4 mức ưu tiên thiết bị',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.62,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GlassToggle(
                value: _enabled,
                size: 0.85,
                onChanged: (val) => setState(() => _enabled = val),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Ngưỡng công suất đỉnh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngưỡng công suất đỉnh:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(_thresholdWatts / 1000).toStringAsFixed(1)} kW (${_thresholdWatts.round()}W)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassSlider(
            value: ((_thresholdWatts - 1500) / 6500).clamp(0.0, 1.0),
            height: 44,
            leadingIcon: Icons.bolt_rounded,
            trailingIcon: Icons.speed_rounded,
            label: '${(_thresholdWatts / 1000).toStringAsFixed(1)} kW',
            onChanged: (val) {
              final snapped = 1500.0 + ((val * 26).round() * 250.0);
              setState(() => _thresholdWatts = snapped.clamp(1500.0, 8000.0));
            },
          ),
          const SizedBox(height: AppSpacing.sm + 4),

          // Mức khuyên dùng nhanh
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs + 2,
            children: [
              for (final preset in <(String, double)>[
                ('3.0 kW', 3000),
                ('4.0 kW', 4000),
                ('6.0 kW', 6000),
              ])
                GlassFilterChip(
                  label: preset.$1,
                  selected: (_thresholdWatts - preset.$2).abs() < 50,
                  onTap: () {
                    setState(() => _thresholdWatts = preset.$2);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),

          // Chế độ xử lý
          GlassSegmentedControl(
            segments: const [
              GlassSegment(label: 'Tự động ngắt'),
              GlassSegment(label: 'Chỉ cảnh báo'),
            ],
            selectedIndex: _mode == 'ALERT_ONLY' ? 1 : 0,
            onChanged: (idx) {
              setState(() {
                _mode = idx == 1 ? 'ALERT_ONLY' : 'AUTO_SHED';
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm + 4),

          // 4 tầng ưu tiên
          Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs + 2,
            children: [
              _DrPriorityBadge(
                label: '1. Khẩn cấp (Cấm ngắt)',
                color: danger,
              ),
              _DrPriorityBadge(
                label: '2. Cốt lõi (24/7)',
                color: accent,
              ),
              const _DrPriorityBadge(
                label: '3. Tiện nghi (Đợt 2)',
                color: AppColors.auroraWarning,
              ),
              const _DrPriorityBadge(
                label: '4. Phụ trợ (Ngắt trước)',
                color: AppColors.orbViolet,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Nút Lưu & Thử nghiệm
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: accent,
                    foregroundColor: isDark
                        ? AppColors.auroraCanvasTop
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.auroraCanvasTop
                                : Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(
                    _isSaving ? 'Đang lưu...' : 'Lưu Hạn Mức',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: _isEvaluating ? null : () => _evaluatePeak(),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text(
                    'Đánh giá tải',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                    foregroundColor: AppColors.auroraWarning,
                    side: BorderSide(
                      color: AppColors.auroraWarning.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: _isEvaluating
                      ? null
                      : () => _evaluatePeak(simulatedWatts: 5500),
                  child: const Text(
                    'Thử 5.5 kW',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                    foregroundColor: danger,
                    side: BorderSide(color: danger.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: _isEvaluating
                      ? null
                      : () => _evaluatePeak(simulatedWatts: 6800),
                  child: const Text(
                    'Quá tải 6.8 kW',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          if (_evaluation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              decoration: BoxDecoration(
                color: (isOverload ? AppColors.auroraWarning : mint).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: (isOverload ? AppColors.auroraWarning : mint)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _evaluation!.message.isNotEmpty
                        ? _evaluation!.message
                        : _evaluation!.status,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isOverload ? AppColors.auroraWarning : mint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Công suất đo: ${_evaluation!.totalCurrentWatts.round()}W / Ngưỡng: ${_evaluation!.peakThresholdWatts.round()}W • Đã hạ: -${_evaluation!.wattsSaved.round()}W',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                  if (_evaluation!.sheddedDevices.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _evaluation!.sheddedDevices
                          .map(
                            (name) => GlassStatusPill(
                              icon: Icons.power_off_rounded,
                              label: name,
                              color: danger,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrPriorityBadge extends StatelessWidget {
  const _DrPriorityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Energy Savings Tip
// ─────────────────────────────────────────────────────────────────────
class _EnergySavingsTipCard extends StatelessWidget {
  const _EnergySavingsTipCard({required this.currentTier, required this.mint});

  final int currentTier;
  final Color mint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      radius: AppRadius.card,
      blur: GlassTokens.blurSm,
      fill: mint.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: mint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.eco_rounded, color: mint, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mẹo Tối Ưu Phụ Tải Đỉnh',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: mint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentTier >= 4
                      ? 'Gia đình bạn đang ở Bậc $currentTier. Hãy cài đặt tự động ngắt bình nóng lạnh và điều chỉnh điều hòa lên 26°C trong khung giờ cao điểm (17:00 – 20:00) để tiết kiệm tới 20% chi phí.'
                      : 'Mức tiêu thụ hiện đang ở Bậc $currentTier an toàn. Tiếp tục duy trì thói quen tắt thiết bị khi ra khỏi phòng để giữ hóa đơn ở bậc thấp.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Loading & Error States
// ─────────────────────────────────────────────────────────────────────
class _LoadingEnergySection extends StatelessWidget {
  const _LoadingEnergySection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorEnergySection extends StatelessWidget {
  const _ErrorEnergySection({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.auroraError,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Lỗi tải dữ liệu năng lượng',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
