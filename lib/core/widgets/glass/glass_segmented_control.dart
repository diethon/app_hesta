import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

class GlassSegment {
  const GlassSegment({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// Segmented control kính với thumb trượt mượt giữa các lựa chọn.
class GlassSegmentedControl extends StatelessWidget {
  const GlassSegmentedControl({
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<GlassSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final thumbColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.95);

    return GlassContainer(
      radius: AppRadius.lg,
      blur: GlassTokens.blurSm,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;
          return SizedBox(
            height: 40,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: GlassTokens.durationMed,
                  curve: GlassTokens.curve,
                  left: segmentWidth * selectedIndex,
                  width: segmentWidth,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: thumbColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: GlassTokens.shadowSoft,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(segments.length, (index) {
                    final segment = segments[index];
                    final selected = index == selectedIndex;
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: selected,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(index);
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (segment.icon != null) ...[
                                  Icon(
                                    segment.icon,
                                    size: 16,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                Text(
                                  segment.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
