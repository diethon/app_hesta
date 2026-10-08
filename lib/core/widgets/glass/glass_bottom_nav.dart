import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Bottom nav kính nổi: bo pill, blur lớn, icon active có glow + dot.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final inactive = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.45);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: GlassContainer(
        radius: AppRadius.hero,
        blur: GlassTokens.blurLg,
        shadows: GlassTokens.shadowSoft,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: GlassTokens.durationFast,
                          curve: GlassTokens.curve,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
                                : Colors.transparent,
                            boxShadow: selected
                                ? GlassTokens.glow(accent, intensity: 0.5)
                                : null,
                          ),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 24,
                            color: selected ? accent : inactive,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedOpacity(
                          duration: GlassTokens.durationFast,
                          opacity: selected ? 1 : 0,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
