import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_tokens.dart';
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

  String _formatRepeatDays(List<int> days) {
    if (days.isEmpty) return '';
    if (days.length == 7) return 'Hàng ngày';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Thứ 2 - Thứ 6';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Cuối tuần (T7, CN)';
    }
    const dayNames = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };
    return days.map((d) => dayNames[d] ?? 'T$d').join(', ');
  }

  String _translateAction(String action) {
    switch (action.toUpperCase()) {
      case 'TURN_ON':
        return 'Bật nguồn';
      case 'TURN_OFF':
        return 'Tắt nguồn';
      case 'TOGGLE':
        return 'Đổi trạng thái';
      case 'SET_TEMPERATURE':
        return 'Cài đặt nhiệt độ';
      case 'SET_BRIGHTNESS':
        return 'Chỉnh độ sáng';
      case 'OPEN':
        return 'Mở rèm/cửa';
      case 'CLOSE':
        return 'Đóng rèm/cửa';
      case 'LOCK':
        return 'Khóa cửa';
      case 'UNLOCK':
        return 'Mở khóa';
      default:
        return action;
    }
  }

  IconData _getDeviceIcon(String? deviceName) {
    final name = (deviceName ?? '').toLowerCase();
    if (name.contains('đèn') || name.contains('light')) {
      return Icons.lightbulb_rounded;
    }
    if (name.contains('lạnh') ||
        name.contains('điều hòa') ||
        name.contains('ac')) {
      return Icons.ac_unit_rounded;
    }
    if (name.contains('rèm') || name.contains('curtain')) {
      return Icons.curtains_rounded;
    }
    if (name.contains('khóa') || name.contains('lock')) {
      return Icons.lock_rounded;
    }
    if (name.contains('quạt') || name.contains('fan')) {
      return Icons.mode_fan_off_rounded;
    }
    if (name.contains('tivi') || name.contains('tv')) {
      return Icons.tv_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    Color confidenceColor = mint;
    if (recommendation.confidencePercent < 80) {
      confidenceColor = AppColors.auroraWarning;
    } else if (recommendation.confidencePercent < 88) {
      confidenceColor = accent;
    }

    final repeatDaysStr =
        _formatRepeatDays(recommendation.triggerCondition.repeatDays);
    final deviceIcon = _getDeviceIcon(recommendation.deviceName);

    return GlassCard(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadows: recommendation.confidencePercent >= 90
          ? GlassTokens.glow(mint, intensity: 0.2)
          : null,
      borderGradient: recommendation.confidencePercent >= 90
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                mint.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.08),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Device Icon, Name, and Confidence Score Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    color: (isDark ? AppColors.orbViolet : Colors.purple)
                        .withValues(alpha: 0.35),
                  ),
                  boxShadow: GlassTokens.glow(
                    isDark ? AppColors.orbViolet : Colors.purple,
                    intensity: 0.25,
                  ),
                ),
                child: Icon(
                  deviceIcon,
                  size: 22,
                  color: isDark ? AppColors.orbViolet : Colors.purple,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.deviceName ?? 'Gợi ý tự động hóa',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.onDark : AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.psychology_rounded,
                          size: 13,
                          color: AppColors.onDarkFaint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mô hình BehaviorML phát hiện',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.onDarkMuted
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              GlassStatusPill(
                label: '${recommendation.confidencePercent}% tin cậy',
                color: confidenceColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Habit Explanation
          Text(
            recommendation.explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.onDark : AppColors.onSurface,
              height: 1.45,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Visual IF -> THEN Recipe Flow Container
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trigger (WHEN / KHI)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'KHI',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.onDarkMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.triggerCondition.time != null
                                ? 'Lúc ${recommendation.triggerCondition.time}'
                                : 'Theo sự kiện hoạt động',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.onDark
                                  : AppColors.onSurface,
                            ),
                          ),
                          if (repeatDaysStr.isNotEmpty)
                            Text(
                              repeatDaysStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.onDarkMuted
                                    : AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Container(
                    width: 1.5,
                    height: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.15),
                  ),
                ),

                // Proposed Action (THEN / THÌ)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: mint.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: mint.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'THÌ',
                        style: TextStyle(
                          color: mint,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: AppColors.onDarkMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translateAction(
                              recommendation.proposedAction.action,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.onDark
                                  : AppColors.onSurface,
                            ),
                          ),
                          if (recommendation
                              .proposedAction.parameters.isNotEmpty)
                            Text(
                              recommendation.proposedAction.parameters.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(', '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.onDarkMuted
                                    : AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Actions or Resolved History
          if (recommendation.isPending) ...[
            Row(
              children: [
                // Approve Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onApprove();
                    },
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text(
                      'Chấp nhận & Tạo quy tắc',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mint,
                      foregroundColor: const Color(0xFF032612),
                      elevation: 0,
                      shadowColor: mint.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: AppSpacing.md,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Reject Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onReject();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

                // Dismiss Button
                IconButton(
                  icon: const Icon(
                    Icons.visibility_off_outlined,
                    size: 19,
                    color: AppColors.onDarkMuted,
                  ),
                  tooltip: 'Tạm ẩn đề xuất',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDismiss();
                  },
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: AppColors.onDarkFaint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recommendation.resolvedAt != null
                          ? 'Xử lý: ${DateFormat('dd/MM HH:mm').format(recommendation.resolvedAt!)}'
                          : 'Đã lưu trong lịch sử',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.onDarkFaint : Colors.grey,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                GlassStatusPill(
                  label: recommendation.status == 'APPROVED'
                      ? 'ĐÃ DUYỆT'
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
