import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

/// Thẻ kính tương tác: press → scale 0.97, haptic nhẹ khi tap.
class GlassCard extends StatefulWidget {
  const GlassCard({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.card,
    this.blur = GlassTokens.blurMd,
    this.active = false,
    this.fill,
    this.borderGradient,
    this.shadows,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final bool active;
  final Color? fill;
  final Gradient? borderGradient;
  final List<BoxShadow>? shadows;
  final String? semanticLabel;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      duration: GlassTokens.durationFast,
      curve: GlassTokens.curve,
      scale: _pressed ? GlassTokens.pressedScale : 1.0,
      child: GlassContainer(
        padding: widget.padding,
        radius: widget.radius,
        blur: widget.blur,
        active: widget.active,
        fill: widget.fill,
        borderGradient: widget.borderGradient,
        shadows: widget.shadows,
        child: widget.child,
      ),
    );

    if (widget.onTap == null && widget.onLongPress == null) return card;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: card,
      ),
    );
  }
}
