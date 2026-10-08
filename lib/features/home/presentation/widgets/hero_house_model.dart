import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/glass_tokens.dart';

/// Mô hình 3D ngôi nhà isometric trong hero card của Home.
///
/// Lazy-init sau first frame để không chặn khung hình đầu; trong lúc
/// WebView của model_viewer khởi động sẽ hiển thị shimmer placeholder.
class HeroHouseModel extends StatefulWidget {
  const HeroHouseModel({super.key});

  @override
  State<HeroHouseModel> createState() => _HeroHouseModelState();
}

class _HeroHouseModelState extends State<HeroHouseModel> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: GlassTokens.durationSlow,
        child: _ready
            ? const ModelViewer(
                key: ValueKey('house-model'),
                src: 'assets/models/modern_house.glb',
                alt: 'Modern house 3D model',
                autoRotate: true,
                cameraControls: true,
                disableZoom: true,
                backgroundColor: Colors.transparent,
                cameraOrbit: '45deg 60deg auto',
                interactionPrompt: InteractionPrompt.none,
              )
            : const _ShimmerPlaceholder(key: ValueKey('house-shimmer')),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder({super.key});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(0 + 2 * _controller.value, 0),
              colors: [base, highlight, base],
            ),
          ),
          child: Center(
            child: Icon(Icons.home_work_outlined, size: 48, color: highlight),
          ),
        );
      },
    );
  }
}
