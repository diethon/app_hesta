import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/glass/glass_status_pill.dart';
import '../../domain/recommendation_models.dart';

class RecommendationItemCard extends StatelessWidget {
  const RecommendationItemCard({
    required this.recommendation,
    required this.onApprove,
    required this.onReject,
    required this.onDismiss,
    super.key,
  });

  final Recommendation recommendation;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    Color confidenceColor = mint;
    if (recommendation.confidencePercent < 85) {
      confidenceColor = accent;
    } else if (recommendation.confidencePercent < 80) {
      confidenceColor = AppColors.auroraWarning;
    }

    return GlassCard(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Confidence & Sparkles Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: isDark ? AppColors.orbViolet : Colors.purple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    recommendation.deviceName ?? 'Gợi ý tự động hóa',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GlassStatusPill(
                label: '${recommendation.confidencePercent}% tin cậy',
                color: confidenceColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Explanation
          Text(
            recommendation.explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onDark : AppColors.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Proposed Trigger & Action details
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Điều kiện: ${recommendation.triggerCondition.time ?? "Theo sự kiện"}'
                        '${recommendation.triggerCondition.repeatDays.isNotEmpty ? " • Các ngày trong tuần" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded,
                        size: 15, color: mint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đề xuất: ${recommendation.proposedAction.action}'
                        '${recommendation.proposedAction.parameters.isNotEmpty ? " (${recommendation.proposedAction.parameters})" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Buttons
          if (recommendation.isPending) ...[
            Row(
              children: [
                // Approve Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Chấp nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mint,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Reject Button
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

                // Dismiss Button
                IconButton(
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  tooltip: 'Bỏ qua',
                  onPressed: onDismiss,
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trạng thái đề xuất:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                GlassStatusPill(
                  label: recommendation.status == 'APPROVED'
                      ? 'ĐÃ CHẤP NHẬN'
                      : (recommendation.status == 'REJECTED'
                          ? 'ĐÃ TỪ CHỐI'
                          : 'ĐÃ BỎ QUA'),
                  color: recommendation.status == 'APPROVED'
                      ? mint
                      : (recommendation.status == 'REJECTED'
                          ? AppColors.error
                          : Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
