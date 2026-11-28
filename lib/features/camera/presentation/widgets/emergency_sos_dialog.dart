import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_tokens.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../../data/camera_providers.dart';
import '../../domain/fall_incident.dart';

class EmergencySosDialog extends ConsumerWidget {
  const EmergencySosDialog({
    required this.incident,
    required this.countdown,
    super.key,
  });

  static const MethodChannel _dialerChannel = MethodChannel(
    'com.syna.smarthome/dialer',
  );

  final FallIncident incident;
  final int countdown;

  Future<void> _callEmergency115(BuildContext context) async {
    try {
      await _dialerChannel.invokeMethod<bool>('dial', {'number': '115'});
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Đang kết nối cuộc gọi khẩn cấp 115...'),
            backgroundColor: AppColors.auroraError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEscalated = incident.isEscalated || countdown <= 0;
    final isAcknowledged = incident.state == 'ACKNOWLEDGED';
    final isMuted = ref.watch(activeFallControllerProvider).isMuted;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1.0),
        duration: GlassTokens.durationSlow,
        curve: GlassTokens.curve,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: GlassContainer(
          radius: AppRadius.card,
          blur: GlassTokens.blurLg,
          fill: AppColors.auroraCanvasMid.withValues(alpha: 0.94),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.auroraError.withValues(
                alpha: isEscalated ? 0.95 : 0.75,
              ),
              AppColors.auroraError.withValues(alpha: 0.22),
            ],
          ),
          shadows: GlassTokens.glow(
            AppColors.auroraError,
            intensity: isEscalated ? 1.0 : 0.7,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header với icon cảnh báo phát sáng & nút tắt âm
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.auroraError.withValues(alpha: 0.18),
                        border: Border.all(
                          color: AppColors.auroraError.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.auroraError,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEscalated
                                ? 'KHẨN CẤP: ĐÃ PHÁT TÍN HIỆU SOS!'
                                : 'PHÁT HIỆN TÉ NGÃ KHẨN CẤP',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.auroraError,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            incident.roomName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: AppColors.onDarkMuted,
                      ),
                      onPressed: () => ref
                          .read(activeFallControllerProvider.notifier)
                          .toggleMute(),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                if (!isAcknowledged && !isEscalated) ...[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: CircularProgressIndicator(
                          value: (countdown / 30).clamp(0.0, 1.0),
                          strokeWidth: 6,
                          backgroundColor: AppColors.onDark.withValues(
                            alpha: 0.12,
                          ),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.auroraError,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$countdown',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppColors.onDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'giây',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.onDarkMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  Text(
                    'Tự động gửi báo động SOS tới người thân và 115 khi hết giờ',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onDarkMuted,
                    ),
                  ),
                ] else if (isEscalated) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.auroraError.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.auroraError.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sos_rounded,
                          color: AppColors.auroraError,
                          size: 24,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            'ĐANG LIÊN LẠC ĐỘI CỨU HỘ VÀ TRUNG TÂM Y TẾ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.auroraError,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Telemetry Metrics Grid
                GlassContainer(
                  radius: AppRadius.lg,
                  blur: GlassTokens.blurSm,
                  fill: GlassTokens.fillDarkActive,
                  borderGradient: GlassTokens.borderGradient(Brightness.dark),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm + 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricItem(
                        label: 'Góc nghiêng',
                        value:
                            '${incident.metrics.spineAngle.toStringAsFixed(1)}°',
                        color: AppColors.auroraWarning,
                      ),
                      _MetricItem(
                        label: 'Gia tốc',
                        value: '${incident.metrics.accelG.toStringAsFixed(1)}G',
                        color: AppColors.auroraError,
                      ),
                      _MetricItem(
                        label: 'Độ tin cậy',
                        value: '${(incident.confidenceScore * 100).toInt()}%',
                        color: AppColors.auroraMint,
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
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.auroraMint,
                          foregroundColor: AppColors.auroraCanvasTop,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        onPressed: () {
                          unawaited(
                            ref
                                .read(activeFallControllerProvider.notifier)
                                .dismiss(),
                          );
                          if (ModalRoute.of(context)?.isCurrent ?? false) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 22),
                        label: const Text(
                          'TÔI ỔN (HỦY BÁO ĐỘNG)',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              foregroundColor: AppColors.auroraError,
                              side: BorderSide(
                                color: AppColors.auroraError.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                            onPressed: () =>
                                unawaited(_callEmergency115(context)),
                            icon: const Icon(
                              Icons.phone_in_talk_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'GỌI 115',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              foregroundColor: isAcknowledged
                                  ? AppColors.auroraMint
                                  : AppColors.auroraAccent,
                              side: BorderSide(
                                color:
                                    (isAcknowledged
                                            ? AppColors.auroraMint
                                            : AppColors.auroraAccent)
                                        .withValues(alpha: 0.65),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                            onPressed: isAcknowledged
                                ? null
                                : () {
                                    unawaited(
                                      ref
                                          .read(
                                            activeFallControllerProvider
                                                .notifier,
                                          )
                                          .acknowledge(),
                                    );
                                  },
                            icon: const Icon(Icons.shield_outlined, size: 18),
                            label: Text(
                              isAcknowledged ? 'ĐÃ XÁC NHẬN' : 'XÁC NHẬN',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: AppColors.orbTeal,
                          side: BorderSide(
                            color: AppColors.orbTeal.withValues(alpha: 0.65),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(activeFallControllerProvider.notifier)
                              .resolve();
                          if (context.mounted &&
                              (ModalRoute.of(context)?.isCurrent ?? false)) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        icon: const Icon(Icons.task_alt_rounded, size: 18),
                        label: const Text(
                          'HOÀN TẤT CỨU NẠN (ĐÓNG SỰ CỐ)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.onDarkMuted, fontSize: 10),
        ),
      ],
    );
  }
}
