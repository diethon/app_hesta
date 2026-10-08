import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_tokens.dart';

/// Dải màu liên tục (Spectrum Ribbon) cho phép vuốt/kéo mượt mà để chọn màu RGB
/// mà không cần nhập tay chỉ số.
class ColorSpectrumSlider extends StatefulWidget {
  const ColorSpectrumSlider({
    required this.currentColor,
    required this.onColorChanged,
    this.onColorChangeEnd,
    super.key,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<Color>? onColorChangeEnd;

  @override
  State<ColorSpectrumSlider> createState() => _ColorSpectrumSliderState();
}

class _ColorSpectrumSliderState extends State<ColorSpectrumSlider> {
  late double _hue; // 0.0 -> 360.0

  @override
  void initState() {
    super.initState();
    _hue = HSVColor.fromColor(widget.currentColor).hue;
  }

  @override
  void didUpdateWidget(ColorSpectrumSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColor != widget.currentColor) {
      _hue = HSVColor.fromColor(widget.currentColor).hue;
    }
  }

  void _handleTouch(double localX, double width, {bool isEnd = false}) {
    final clampedX = localX.clamp(0.0, width);
    final ratio = clampedX / (width <= 0 ? 1 : width);
    final newHue = (ratio * 360.0).clamp(0.0, 360.0);

    setState(() {
      _hue = newHue;
    });

    final selectedColor = HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor();
    widget.onColorChanged(selectedColor);

    if (isEnd) {
      HapticFeedback.selectionClick();
      widget.onColorChangeEnd?.call(selectedColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbX = (width * (_hue / 360.0)).clamp(16.0, width - 16.0);
        final activeColor = HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        boxShadow: GlassTokens.glow(activeColor, intensity: 0.9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'DẢI MÀU RGB',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Hue: ${_hue.round()}°',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                HapticFeedback.lightImpact();
                _handleTouch(details.localPosition.dx, width);
              },
              onHorizontalDragUpdate: (details) {
                _handleTouch(details.localPosition.dx, width);
              },
              onHorizontalDragEnd: (details) {
                _handleTouch(thumbX, width, isEnd: true);
              },
              onTapDown: (details) {
                _handleTouch(details.localPosition.dx, width, isEnd: true);
              },
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Spectrum Track
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000), // Red 0°
                            Color(0xFFFF7F00), // Orange 30°
                            Color(0xFFFFFF00), // Yellow 60°
                            Color(0xFF00FF00), // Green 120°
                            Color(0xFF00FFFF), // Cyan 180°
                            Color(0xFF0000FF), // Blue 240°
                            Color(0xFF8B00FF), // Violet 270°
                            Color(0xFFFF00FF), // Magenta 300°
                            Color(0xFFFF0000), // Red 360°
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    // Glass Thumb (Magnifier ring)
                    Positioned(
                      left: thumbX - 18,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.7),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
