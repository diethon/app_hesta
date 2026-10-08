import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

/// "Kéo để xác nhận" (mở khoá cửa…): bắt buộc kéo thumb tới cuối track,
/// không thể tap.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    required this.label,
    required this.onConfirmed,
    this.icon = Icons.lock_open_rounded,
    this.color,
    this.height = 64,
    super.key,
  });

  final String label;
  final VoidCallback onConfirmed;
  final IconData icon;

  /// Màu thumb/glow; mặc định accent.
  final Color? color;
  final double height;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  /// 0..1 — vị trí thumb dọc track.
  double _progress = 0;
  bool _confirmed = false;

  static const _thumbPadding = 6.0;

  void _onDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (_confirmed) return;
    final travel = trackWidth - widget.height;
    setState(() {
      _progress = (_progress + details.delta.dx / travel).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd() {
    if (_confirmed) return;
    if (_progress >= 0.92) {
      setState(() {
        _progress = 1;
        _confirmed = true;
      });
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
      // Tự reset sau khi xác nhận để có thể thao tác lại.
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _confirmed = false;
            _progress = 0;
          });
        }
      });
    } else {
      setState(() => _progress = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = widget.color ?? theme.colorScheme.primary;
    final thumbSize = widget.height - _thumbPadding * 2;

    return Semantics(
      label: widget.label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final travel = trackWidth - thumbSize - _thumbPadding * 2;
          return GlassContainer(
            radius: AppRadius.pill,
            blur: GlassTokens.blurSm,
            shadows: _confirmed ? GlassTokens.glow(tint, intensity: 0.8) : null,
            child: SizedBox(
              height: widget.height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Nhãn mờ dần khi kéo.
                  Opacity(
                    opacity: (1 - _progress * 1.6).clamp(0.0, 1.0),
                    child: Text(
                      widget.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 0.4,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                  // Vệt fill phía sau thumb.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _thumbPadding * 2 + thumbSize + travel * _progress,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        color: tint.withValues(alpha: 0.25 + 0.35 * _progress),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _thumbPadding + travel * _progress,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) =>
                          _onDragUpdate(details, trackWidth),
                      onHorizontalDragEnd: (_) => _onDragEnd(),
                      onHorizontalDragCancel: _onDragEnd,
                      child: AnimatedContainer(
                        duration: GlassTokens.durationFast,
                        curve: GlassTokens.curve,
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tint,
                          boxShadow: GlassTokens.glow(tint, intensity: 0.7),
                        ),
                        child: Icon(
                          _confirmed
                              ? Icons.check_rounded
                              : (_progress > 0
                                    ? Icons.chevron_right_rounded
                                    : widget.icon),
                          color: Colors.white,
                          size: thumbSize * 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
