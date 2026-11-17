import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../data/camera_providers.dart';
import '../../domain/fall_incident.dart';

class EmergencySosDialog extends ConsumerWidget {
  const EmergencySosDialog({
    required this.incident,
    required this.countdown,
    super.key,
  });

  final FallIncident incident;
  final int countdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEscalated = incident.isEscalated || countdown <= 0;
    final isAcknowledged = incident.state == 'ACKNOWLEDGED';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E0A0A),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isEscalated ? Colors.redAccent : Colors.red,
                  width: isEscalated ? 3.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with pulsing alert badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEscalated
                                ? 'KHẨN CẤP: ĐÃ PHÁT TÍN HIỆU SOS!'
                                : 'PHÁT HIỆN TÉ NGÃ KHẨN CẤP',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            incident.roomName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      ref.watch(activeFallControllerProvider).isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => ref
                        .read(activeFallControllerProvider.notifier)
                        .toggleMute(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Countdown Ring & Incident Type
              if (!isAcknowledged && !isEscalated) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: (countdown / 30).clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$countdown',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'giây',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tự động gửi báo động SOS tới người thân và 115 khi hết giờ',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ] else if (isEscalated) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sos_rounded, color: Colors.redAccent, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'ĐANG LIÊN LẠC ĐỘI CỨU HỘ VÀ TRUNG TÂM Y TẾ',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Telemetry Metrics Grid
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricItem(
                      label: 'Góc nghiêng',
                      value: '${incident.metrics.spineAngle.toStringAsFixed(1)}°',
                      color: Colors.orangeAccent,
                    ),
                    _MetricItem(
                      label: 'Gia tốc',
                      value: '${incident.metrics.accelG.toStringAsFixed(1)}G',
                      color: Colors.amberAccent,
                    ),
                    _MetricItem(
                      label: 'Độ tin cậy',
                      value: '${(incident.confidenceScore * 100).toInt()}%',
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () {
                        ref.read(activeFallControllerProvider.notifier).dismiss();
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 22),
                      label: const Text(
                        'TÔI ỔN (HỦY BÁO ĐỘNG)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang kết nối cuộc gọi khẩn cấp 115...'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                          label: const Text('GỌI 115'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () {
                            ref
                                .read(activeFallControllerProvider.notifier)
                                .acknowledge();
                          },
                          icon: const Icon(Icons.shield_outlined, size: 18),
                          label: const Text('XÁC NHẬN'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
