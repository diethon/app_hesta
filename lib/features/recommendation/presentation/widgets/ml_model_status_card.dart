import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_tokens.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/glass/glass_status_pill.dart';
import '../../data/recommendation_providers.dart';

class MlModelStatusCard extends ConsumerStatefulWidget {
  const MlModelStatusCard({super.key});

  @override
  ConsumerState<MlModelStatusCard> createState() => _MlModelStatusCardState();
}

class _MlModelStatusCardState extends ConsumerState<MlModelStatusCard> {
  bool _isRetraining = false;

  Future<void> _handleRetrain() async {
    setState(() => _isRetraining = true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final result =
        await ref.read(mlModelStatusProvider.notifier).retrain();

    if (mounted) {
      setState(() => _isRetraining = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isReady
                  ? 'Huấn luyện lại mô hình thành công! Độ chính xác: ${result.accuracyPercent}%'
                  : 'Trạng thái mô hình: ${result.status}',
            ),
            backgroundColor: result.isReady
                ? (isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight)
                : AppColors.auroraWarning,
            behavior: SnackBarBehavior.floating,
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
          statusLabel = 'KHỞI ĐỘNG (COLD START)';
        } else if (model.isTraining) {
          badgeColor = accent;
          statusLabel = 'ĐANG HUẤN LUYỆN';
        }

        return GlassCard(
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark
                                  ? AppColors.orbViolet
                                  : Colors.purple)
                              .withValues(alpha: 0.2),
                          boxShadow: GlassTokens.glow(
                            isDark ? AppColors.orbViolet : Colors.purple,
                            intensity: 0.4,
                          ),
                        ),
                        child: Icon(
                          Icons.psychology_rounded,
                          size: 20,
                          color: isDark ? AppColors.orbViolet : Colors.purple,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI & Machine Learning Engine',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Phiên bản: ${model.version}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.onDarkMuted
                                  : AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GlassStatusPill(
                    label: statusLabel,
                    color: badgeColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Metrics Row
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
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
                    Container(width: 1, height: 28, color: Colors.white10),
                    _MetricItem(
                      label: 'Mẫu học',
                      value: '${model.trainSamples ?? 0}',
                      color: accent,
                    ),
                    Container(width: 1, height: 28, color: Colors.white10),
                    _MetricItem(
                      label: 'Ngưỡng tin cậy',
                      value:
                          '${(model.confidenceThreshold * 100).round()}%',
                      color: isDark
                          ? AppColors.orbViolet
                          : Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Retrain Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mô hình tự động học theo thói quen bật/tắt thiết bị.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.onDarkFaint
                          : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  InkWell(
                    onTap: _isRetraining ? null : _handleRetrain,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      child: Row(
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
                            Icon(Icons.refresh_rounded, size: 16, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            _isRetraining ? 'Đang train...' : 'Huấn luyện lại',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
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
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox(),
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
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
