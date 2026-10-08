import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

/// Pill trạng thái kính: icon/dot màu + nhãn (VD "Cửa 1/4 mở").
class GlassStatusPill extends StatelessWidget {
  const GlassStatusPill({
    required this.label,
    this.value,
    this.icon,
    this.color,
    this.onTap,
    super.key,
  });

  final String label;

  /// Giá trị nhấn mạnh đứng trước nhãn (VD "1/4").
  final String? value;
  final IconData? icon;

  /// Màu của icon/dot; mặc định accent.
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;

    final pill = GlassContainer(
      radius: AppRadius.pill,
      blur: GlassTokens.blurSm,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: tint)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tint,
                shape: BoxShape.circle,
                boxShadow: GlassTokens.glow(tint, intensity: 0.6),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          if (value != null) ...[
            Text(
              value!,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;
    return Semantics(
      button: true,
      child: GestureDetector(onTap: onTap, child: pill),
    );
  }
}
