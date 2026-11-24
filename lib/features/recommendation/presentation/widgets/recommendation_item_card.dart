import 'package:flutter/material.dart';
import '../../../../core/utils/time_format.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/studio.dart';
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

  static IconData deviceIcon(String? deviceName) {
    final name = (deviceName ?? '').toLowerCase();
    if (name.contains('đèn') || name.contains('light')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (name.contains('lạnh') || name.contains('điều hòa') || name.contains('ac')) {
      return Icons.ac_unit_rounded;
    }
    if (name.contains('rèm') || name.contains('curtain')) {
      return Icons.curtains_rounded;
    }
    if (name.contains('khóa') || name.contains('lock')) {
      return Icons.lock_outline_rounded;
    }
    if (name.contains('quạt') || name.contains('fan')) {
      return Icons.air_rounded;
    }
    if (name.contains('tivi') || name.contains('tv')) {
      return Icons.tv_rounded;
    }
    return Icons.devices_other_rounded;
  }

  /// Mức phù hợp bằng lời thay cho con số phần trăm thô.
  static String fitLabel(int percent) => percent >= 90
      ? 'Rất phù hợp'
      : percent >= 80
      ? 'Phù hợp'
      : 'Có thể phù hợp';

  String get _when {
    final t = recommendation.triggerCondition;
    final time = t.time;
    if (time == null || time.isEmpty) return 'Khi có hoạt động tương tự';
    return 'Lúc ${formatHms(time)} · ${describeDays(t.repeatDays)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final theme = Theme.of(context);
    final rec = recommendation;
    final device = rec.deviceName ?? 'Thiết bị';
    final percent = rec.confidencePercent;

    return StudioCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudioIconTile(
                icon: deviceIcon(rec.deviceName),
                active: rec.isPending || rec.isApproved,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gợi ý từ thói quen của bạn',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Độ tin cậy $percent%',
                child: StudioTag(label: fitLabel(percent), color: c.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rec.explanation,
            style: TextStyle(fontSize: 14, height: 1.45, color: c.text),
          ),
          const SizedBox(height: 12),

          // Quy tắc sẽ được tạo, viết thành 2 dòng dễ đọc.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _RuleLine(
                  icon: Icons.schedule_rounded,
                  label: 'Khi',
                  text: _when,
                ),
                const SizedBox(height: 8),
                _RuleLine(
                  icon: Icons.bolt_rounded,
                  label: 'Thì',
                  text:
                      '$device: ${describeAction(rec.proposedAction.action, params: rec.proposedAction.parameters)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (rec.isPending)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onApprove();
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Tạo quy tắc'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onReject();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.muted,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 18,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Không cần'),
                ),
                IconButton(
                  icon: Icon(Icons.visibility_off_outlined, size: 20, color: c.faint),
                  tooltip: 'Ẩn tạm thời',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDismiss();
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                StudioTag(
                  label: rec.isApproved
                      ? 'Đã tạo quy tắc'
                      : rec.status.toUpperCase() == 'REJECTED'
                      ? 'Đã từ chối'
                      : 'Đã ẩn',
                  icon: rec.isApproved
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline_rounded,
                  color: rec.isApproved ? c.on : null,
                ),
                const Spacer(),
                Text(
                  describeWhen(rec.resolvedAt),
                  style: TextStyle(fontSize: 12, color: c.faint),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.icon, required this.label, required this.text});

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: c.accent),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: c.muted),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ),
      ],
    );
  }
}
