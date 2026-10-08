import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../devices/data/device_providers.dart';

class EnergyScreen extends ConsumerStatefulWidget {
  const EnergyScreen({super.key});

  @override
  ConsumerState<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends ConsumerState<EnergyScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late final AnimationController _barAnimCtrl;
  late final Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnim = CurvedAnimation(parent: _barAnimCtrl, curve: GlassTokens.curve);
    _barAnimCtrl.forward();
  }

  @override
  void dispose() {
    _barAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    // Giữ liên kết provider để số liệu tổng dùng dữ liệu thật khi có.
    ref.watch(devicesControllerProvider);
    const totalKwh = 24.5;
    const estimatedCost = 18.42;
    const carbonKg = 12.8;

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
                Text(
                  l10n.energyUsage,
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.energySubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                GlassSegmentedControl(
                  segments: [
                    GlassSegment(label: l10n.periodDaily),
                    GlassSegment(label: l10n.periodWeekly),
                    GlassSegment(label: l10n.periodMonthly),
                  ],
                  selectedIndex: _selectedTab,
                  onChanged: (index) {
                    setState(() => _selectedTab = index);
                    _barAnimCtrl
                      ..reset()
                      ..forward();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                const _EnergyChartCard(),
                const SizedBox(height: AppSpacing.md),

                _DeviceDistributionCard(animation: _barAnim),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bolt_rounded,
                        iconColor: theme.colorScheme.primary,
                        label: l10n.totalUsage,
                        value: '$totalKwh',
                        unit: 'kWh',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.auroraWarning,
                        label: l10n.estimatedCost,
                        value: '\$$estimatedCost',
                        unit: 'USD',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _StatCard(
                  icon: Icons.forest_outlined,
                  iconColor: mint,
                  label: l10n.carbonFootprint,
                  value: '$carbonKg',
                  unit: 'kgCO₂',
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
// Chart Card
// ─────────────────────────────────────────────────────────────────────
class _EnergyChartCard extends StatefulWidget {
  const _EnergyChartCard();

  @override
  State<_EnergyChartCard> createState() => _EnergyChartCardState();
}

class _EnergyChartCardState extends State<_EnergyChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: GlassTokens.curve);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              Flexible(
                child: Text(
                  l10n.consumptionOverTime,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              _Legend(
                color: theme.colorScheme.primary,
                label: l10n.consumption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => CustomPaint(
                size: const Size(double.infinity, 180),
                painter: _EnergyChartPainter(
                  progress: _anim.value,
                  lineColor: theme.colorScheme.primary,
                  gridColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.08,
                  ),
                  peakColor: AppColors.auroraError,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00']
                .map(
                  (t) => Text(
                    t,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _EnergyChartPainter extends CustomPainter {
  _EnergyChartPainter({
    required this.progress,
    required this.lineColor,
    required this.gridColor,
    required this.peakColor,
  });

  final double progress;
  final Color lineColor;
  final Color gridColor;
  final Color peakColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final points = const [
      Offset(0, 0.15),
      Offset(0.14, 0.13),
      Offset(0.25, 0.18),
      Offset(0.38, 0.75),
      Offset(0.5, 0.60),
      Offset(0.62, 0.10),
      Offset(0.75, 0.20),
      Offset(0.88, 0.35),
      Offset(1.0, 0.45),
    ].map((p) => Offset(p.dx * w, (1 - p.dy) * h)).toList();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * progress, h));

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), gridPaint);
    }

    Path buildLine() {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final cp1 = Offset(
          (points[i - 1].dx + points[i].dx) / 2,
          points[i - 1].dy,
        );
        final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
        path.cubicTo(
          cp1.dx,
          cp1.dy,
          cp2.dx,
          cp2.dy,
          points[i].dx,
          points[i].dy,
        );
      }
      return path;
    }

    final areaPath = buildLine()
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.18),
          lineColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(areaPath, gradPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(buildLine(), linePaint);

    final peakPoint = points[3];
    canvas.drawCircle(peakPoint, 6, Paint()..color = peakColor);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Peak: 4.2 kW',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: peakColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, peakPoint + const Offset(10, -8));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_EnergyChartPainter old) =>
      old.progress != progress || old.lineColor != lineColor;
}

// ─────────────────────────────────────────────────────────────────────
// Device Distribution Card
// ─────────────────────────────────────────────────────────────────────
class _DeviceDistributionCard extends StatelessWidget {
  const _DeviceDistributionCard({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final items = [
      (l10n.categoryClimate, 12.4, 0.65),
      (l10n.categoryRefrigeration, 4.2, 0.25),
      (l10n.categoryLighting, 2.8, 0.15),
      (l10n.categoryOthers, 1.5, 0.08),
    ];

    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deviceDistribution, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.$1,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.$2} kWh',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) => LayoutBuilder(
                        builder: (context, constraints) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width:
                                  constraints.maxWidth *
                                  item.$3 *
                                  animation.value,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(
                                      alpha: 0.6,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Eco tip
          GlassContainer(
            radius: AppRadius.lg,
            blur: GlassTokens.blurSm,
            fill: mint.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: mint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.eco_outlined, color: mint, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.efficiencyTip,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: mint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.efficiencyTipBody,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
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
// Stat Card
// ─────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      unit,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
