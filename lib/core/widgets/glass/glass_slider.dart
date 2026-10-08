import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

/// Slider dạng track dày (kiểu HomeKit): kéo trực tiếp trên track,
/// phần fill là màu accent, không có thumb rời.
class GlassSlider extends StatefulWidget {
  const GlassSlider({
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.height = 44,
    this.leadingIcon,
    this.trailingIcon,
    this.label,
    super.key,
  });

  /// Giá trị 0..1.
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double height;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  /// Nhãn hiển thị giữa track (VD "50%").
  final String? label;

  @override
  State<GlassSlider> createState() => _GlassSliderState();
}

class _GlassSliderState extends State<GlassSlider> {
  void _update(Offset localPosition, double width) {
    final next = (localPosition.dx / width).clamp(0.0, 1.0);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      slider: true,
      value: '${(widget.value * 100).round()}%',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) =>
                _update(details.localPosition, width),
            onHorizontalDragEnd: (_) {
              HapticFeedback.lightImpact();
              widget.onChangeEnd?.call(widget.value);
            },
            onTapDown: (details) => _update(details.localPosition, width),
            onTapUp: (_) {
              HapticFeedback.lightImpact();
              widget.onChangeEnd?.call(widget.value);
            },
            child: GlassContainer(
              radius: AppRadius.lg,
              blur: GlassTokens.blurSm,
              child: SizedBox(
                height: widget.height,
                child: Stack(
                  children: [
                    // Fill accent theo giá trị.
                    AnimatedFractionallySizedBox(
                      duration: GlassTokens.durationFast,
                      curve: GlassTokens.curve,
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.value.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.85 : 0.9),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          if (widget.leadingIcon != null)
                            Icon(
                              widget.leadingIcon,
                              size: 18,
                              color: Colors.white,
                            ),
                          const Spacer(),
                          if (widget.label != null)
                            Text(
                              widget.label!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const Spacer(),
                          if (widget.trailingIcon != null)
                            Icon(
                              widget.trailingIcon,
                              size: 18,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
