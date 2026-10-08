import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/glass_tokens.dart';

/// Nền toàn màn hình: gradient tối sâu + các "ambient orb" mờ đặt sau
/// lớp kính — đây là thứ làm kính "có gì để mà mờ".
///
/// Orb là radial gradient tự tan ra transparent (rẻ hơn nhiều so với
/// ImageFilter.blur toàn màn) và tĩnh hoàn toàn để không phá
/// `pumpAndSettle` trong test.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alphas = isDark
        ? GlassTokens.orbAlphaDark
        : GlassTokens.orbAlphaLight;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      AppColors.auroraCanvasTop,
                      AppColors.auroraCanvasMid,
                      AppColors.auroraCanvasBottom,
                    ]
                  : const [
                      AppColors.auroraCanvasTopLight,
                      AppColors.auroraCanvasBottomLight,
                    ],
            ),
          ),
        ),
        _Orb(
          alignment: const Alignment(-1.2, -0.9),
          diameterFactor: 0.9,
          color: GlassTokens.orbColors[0],
          alpha: alphas[0],
        ),
        _Orb(
          alignment: const Alignment(1.3, -0.2),
          diameterFactor: 0.75,
          color: GlassTokens.orbColors[1],
          alpha: alphas[1],
        ),
        _Orb(
          alignment: const Alignment(-0.6, 1.2),
          diameterFactor: 0.8,
          color: GlassTokens.orbColors[2],
          alpha: alphas[2],
        ),
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.alignment,
    required this.diameterFactor,
    required this.color,
    required this.alpha,
  });

  final Alignment alignment;
  final double diameterFactor;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.biggest.shortestSide * diameterFactor;
        return Align(
          alignment: alignment,
          child: IgnorePointer(
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: alpha),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
