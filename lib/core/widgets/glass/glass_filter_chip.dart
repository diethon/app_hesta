import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

/// Chip lọc kính; active → fill accent + chữ đậm, animate mượt.
class GlassFilterChip extends StatelessWidget {
  const GlassFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final foreground = selected
        ? (isDark ? Colors.black : Colors.white)
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: GlassContainer(
          radius: AppRadius.pill,
          blur: GlassTokens.blurSm,
          fill: selected ? accent : null,
          shadows: selected ? GlassTokens.glow(accent, intensity: 0.6) : null,
          child: AnimatedContainer(
            duration: GlassTokens.durationFast,
            curve: GlassTokens.curve,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                AnimatedDefaultTextStyle(
                  duration: GlassTokens.durationFast,
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
