import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/glass_tokens.dart';

/// Thẻ kính nền tảng của design system — điểm DUY NHẤT trong app
/// được phép gọi [BackdropFilter].
///
/// Mọi bề mặt kính (card, app bar, nav, chip, pill…) đều đi qua widget
/// này để đảm bảo blur/fill/viền đồng nhất và mỗi tấm kính được bọc
/// [RepaintBoundary] chống jank.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    this.padding,
    this.radius = AppRadius.card,
    this.blur = GlassTokens.blurMd,
    this.active = false,
    this.fill,
    this.borderGradient,
    this.shadows,
    this.shape = BoxShape.rectangle,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Bo góc (bỏ qua nếu [shape] là circle).
  final double radius;

  /// Sigma blur — lấy từ [GlassTokens], không truyền số tự chế.
  final double blur;

  /// Active → fill sáng hơn (thẻ đang bật).
  final bool active;

  /// Override fill; mặc định theo [GlassTokens.fill].
  final Color? fill;

  /// Override viền gradient; mặc định [GlassTokens.borderGradient].
  final Gradient? borderGradient;

  /// Bóng/glow vẽ NGOÀI vùng clip (glow accent, shadow mềm).
  final List<BoxShadow>? shadows;

  final BoxShape shape;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final effectiveFill = fill ?? GlassTokens.fill(brightness, active: active);
    final gradient = borderGradient ?? GlassTokens.borderGradient(brightness);

    final borderRadius = shape == BoxShape.circle
        ? null
        : BorderRadius.circular(radius);

    Widget content = ClipPath(
      clipper: shape == BoxShape.circle
          ? const ShapeBorderClipper(shape: CircleBorder())
          : ShapeBorderClipper(
              shape: RoundedRectangleBorder(borderRadius: borderRadius!),
            ),
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: CustomPaint(
          foregroundPainter: _GlassBorderPainter(
            gradient: gradient,
            radius: radius,
            shape: shape,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: effectiveFill,
              shape: shape,
              borderRadius: borderRadius,
            ),
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );

    if (shadows != null && shadows!.isNotEmpty) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: borderRadius,
          boxShadow: shadows,
        ),
        child: content,
      );
    }

    return RepaintBoundary(child: content);
  }
}

class _GlassBorderPainter extends CustomPainter {
  const _GlassBorderPainter({
    required this.gradient,
    required this.radius,
    required this.shape,
  });

  final Gradient gradient;
  final double radius;
  final BoxShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = GlassTokens.borderWidth;

    final inset = GlassTokens.borderWidth / 2;
    final inner = rect.deflate(inset);
    if (shape == BoxShape.circle) {
      canvas.drawOval(inner, paint);
    } else {
      // radius có thể là 0 (app bar vuông cạnh) → không được âm sau khi
      // trừ inset, RRect assert radius >= 0.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          inner,
          Radius.circular(clampDouble(radius - inset, 0, double.infinity)),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlassBorderPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.radius != radius ||
      oldDelegate.shape != shape;
}
