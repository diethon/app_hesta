import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_tokens.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/glass/glass_status_pill.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/recommendation_providers.dart';

class MlModelStatusCard extends ConsumerStatefulWidget {
  const MlModelStatusCard({super.key});

  @override
  ConsumerState<MlModelStatusCard> createState() => _MlModelStatusCardState();
}

class _MlModelStatusCardState extends ConsumerState<MlModelStatusCard> {
  bool _isRetraining = false;

  Future<void> _handleRetrain() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _isRetraining = true);

    final result = await ref.read(mlModelStatusProvider.notifier).retrain();

    if (mounted) {
      setState(() => _isRetraining = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isReady
                  ? 'Huấn luyện lại mô hình thành công! Độ chính xác: ${result.accuracyPercent}%'
                  : result.isUnavailable
                      ? 'Dịch vụ Machine Learning hiện chưa khả dụng hoặc đang ngoại tuyến.'
                      : 'Trạng thái mô hình: ${result.status}',
            ),
            backgroundColor: result.isReady
                ? (isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight)
                : AppColors.auroraWarning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(mlModelStatusProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    return statusAsync.when(
      data: (model) {
        Color badgeColor = mint;
        String statusLabel = 'SẴN SÀNG';

        if (model.isColdStart) {
          badgeColor = AppColors.auroraWarning;
          statusLabel = 'TÍCH LŨY DỮ LIỆU';
        } else if (model.isTraining) {
          badgeColor = accent;
          statusLabel = 'ĐANG HUẤN LUYỆN';
        } else if (model.isUnavailable) {
          badgeColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
          statusLabel = 'CHƯA KẾT NỐI ML';
        } else if (model.isNotTrained) {
          badgeColor = AppColors.auroraWarning;
          statusLabel = 'CHƯA HUẤN LUYỆN';
        }

        final formattedDate = model.trainedAt != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(model.trainedAt!)
            : 'Mới khởi tạo';

        return GlassCard(
          radius: AppRadius.card,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                (isDark ? AppColors.orbViolet : Colors.purple)
                                    .withValues(alpha: 0.28),
                                (isDark ? AppColors.orbViolet : Colors.purple)
                                    .withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color:
                                  (isDark ? AppColors.orbViolet : Colors.purple)
                                      .withValues(alpha: 0.35),
                            ),
                            boxShadow: GlassTokens.glow(
                              isDark ? AppColors.orbViolet : Colors.purple,
                              intensity: 0.35,
                            ),
                          ),
                          child: Icon(
                            Icons.psychology_rounded,
                            size: 24,
                            color: isDark ? AppColors.orbViolet : Colors.purple,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mô hình AI & Machine Learning',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${model.modelType} • v${model.version}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.onDarkMuted
                                      : AppColors.onSurfaceVariant,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GlassStatusPill(
                    label: statusLabel,
                    color: badgeColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Cold-start notification if learning period is active
              if (model.isColdStart) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.auroraWarning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.auroraWarning.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        size: 20,
                        color: AppColors.auroraWarning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang quan sát thói quen sinh hoạt',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.auroraWarning,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hệ thống đang tích lũy dữ liệu bật/tắt thiết bị để đưa ra đề xuất tự động chính xác nhất cho bạn.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.onDarkMuted
                                    : AppColors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Metrics Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricItem(
                      label: 'Độ chính xác',
                      value: '${model.accuracyPercent}%',
                      color: mint,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    _MetricItem(
                      label: 'Mẫu học',
                      value: '${model.trainSamples ?? 0}',
                      color: accent,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    _MetricItem(
                      label: 'Ngưỡng tin cậy',
                      value: '${(model.confidenceThreshold * 100).round()}%',
                      color: isDark ? AppColors.orbViolet : Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Bottom Info & Retrain Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.update_rounded,
                          size: 14,
                          color: AppColors.onDarkFaint,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Cập nhật: $formattedDate',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.onDarkFaint
                                  : Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _isRetraining ? null : _handleRetrain,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isRetraining)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent,
                              ),
                            )
                          else
                            Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: accent,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            _isRetraining ? 'Đang học...' : 'Huấn luyện lại',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const GlassCardSkeleton(height: 160),
      error: (e, _) => GlassCard(
        radius: AppRadius.card,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.auroraWarning,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Không thể kết nối dịch vụ ML: $e',
                style: theme.textTheme.bodySmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: () =>
                  ref.read(mlModelStatusProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onDarkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
