import 'package:flutter/material.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: Stack(
          children: [
            Align(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassContainer(
                      radius: AppRadius.hero,
                      shadows: GlassTokens.glow(accent, intensity: 0.4),
                      child: SizedBox.square(
                        dimension: 140,
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppRadius.xl - 4,
                              ),
                            ),
                            child: Icon(
                              Icons.home_outlined,
                              size: 48,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        backgroundColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                        minHeight: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.appName.toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.splashTagline.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 3,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
