import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_tokens.dart';

/// Slider kính dạng dọc (Vertical Glass Capsule Slider)
/// Cho phép vuốt/kéo ngón tay lên-xuống để chỉnh độ sáng hoặc âm lượng trực quan.
class VerticalGlassSlider extends StatefulWidget {
  const VerticalGlassSlider({
    required this.value, // 0.0 -> 1.0
    required this.onChanged,
    this.onChangeEnd,
    this.accentColor = AppColors.auroraWarning,
    this.height = 200,
    this.width = 72,
    this.icon = Icons.wb_sunny_rounded,
    this.label,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color accentColor;
  final double height;
  final double width;
  final IconData icon;
  final String? label;

  @override
  State<VerticalGlassSlider> createState() => _VerticalGlassSliderState();
}

class _VerticalGlassSliderState extends State<VerticalGlassSlider> {
  late double _currentVal;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentVal = widget.value.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(VerticalGlassSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.value != widget.value) {
      _currentVal = widget.value.clamp(0.0, 1.0);
    }
  }

  void _handleVerticalDrag(double localY, double maxHeight, {bool isEnd = false}) {
    // 0 ở đỉnh, maxHeight ở đáy => Kéo lên là tăng:
    final rawRatio = 1.0 - (localY / (maxHeight <= 0 ? 1 : maxHeight));
    final clampedRatio = rawRatio.clamp(0.0, 1.0);

    setState(() {
      _currentVal = clampedRatio;
      _isDragging = !isEnd;
    });

    widget.onChanged(clampedRatio);

    if (isEnd) {
      HapticFeedback.mediumImpact();
      widget.onChangeEnd?.call(clampedRatio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_currentVal * 100).round();
    final accent = widget.accentColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (details) {
            HapticFeedback.selectionClick();
            _handleVerticalDrag(details.localPosition.dy, widget.height);
          },
          onVerticalDragUpdate: (details) {
            _handleVerticalDrag(details.localPosition.dy, widget.height);
          },
          onVerticalDragEnd: (details) {
            _handleVerticalDrag(
              (1.0 - _currentVal) * widget.height,
              widget.height,
              isEnd: true,
            );
          },
          onTapDown: (details) {
            _handleVerticalDrag(details.localPosition.dy, widget.height, isEnd: true);
          },
          child: AnimatedContainer(
            duration: GlassTokens.durationFast,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.hero),
              color: GlassTokens.fillDark,
              border: Border.all(
                color: _isDragging
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: _isDragging
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : GlassTokens.shadowSoft,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Vùng lấp đầy từ đáy lên (Level Fill)
                FractionallySizedBox(
                  heightFactor: _currentVal.clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          accent.withValues(alpha: 0.85),
                          accent.withValues(alpha: 0.45),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Đường cắt vạch chỉ báo
                Positioned(
                  bottom: (_currentVal * widget.height).clamp(12.0, widget.height - 12.0) - 2,
                  child: Container(
                    width: widget.width * 0.5,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                // Icon & Số % ở trong thanh
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.xs,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Số %
                      Text(
                        '$percent%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                      ),
                      // Icon bên dưới
                      Icon(
                        widget.icon,
                        color: Colors.white.withValues(
                          alpha: _currentVal > 0.15 ? 1.0 : 0.6,
                        ),
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
          ),
        ],
      ],
    );
  }
}
