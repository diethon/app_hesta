import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/glass_tokens.dart';

/// Toggle kiểu Apple trong ngôn ngữ kính; ON = mint + glow, có haptic.
class GlassToggle extends StatelessWidget {
  const GlassToggle({
    required this.value,
    required this.onChanged,
    this.size = 1.0,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Hệ số phóng to/thu nhỏ (1.0 = 48×28).
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onColor = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final offColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.14);
    final disabled = onChanged == null;

    return Semantics(
      toggled: value,
      enabled: !disabled,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () {
                HapticFeedback.lightImpact();
                onChanged!(!value);
              },
        child: Opacity(
          opacity: disabled ? 0.45 : 1,
          child: AnimatedContainer(
            duration: GlassTokens.durationFast,
            curve: GlassTokens.curve,
            width: 48 * size,
            height: 28 * size,
            decoration: BoxDecoration(
              color: value ? onColor : offColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: value
                  ? GlassTokens.glow(onColor, intensity: 0.5)
                  : null,
            ),
            child: AnimatedAlign(
              duration: GlassTokens.durationFast,
              curve: GlassTokens.curve,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22 * size,
                height: 22 * size,
                margin: EdgeInsets.symmetric(horizontal: 3 * size),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
