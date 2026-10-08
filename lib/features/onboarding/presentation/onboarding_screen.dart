import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass/glass.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  static const _icons = [
    Icons.home_outlined,
    Icons.auto_awesome_outlined,
    Icons.security_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: GlassTokens.durationMed,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: GlassTokens.curve,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_currentStep < _icons.length - 1) {
      await _animController.reverse();
      setState(() => _currentStep++);
      await _animController.forward();
    } else {
      await ref.read(appPreferencesProvider).setOnboardingCompleted(true);
      ref.invalidate(appPreferencesProvider);
      ref.invalidate(routerProvider);
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final steps = [
      (title: l10n.onboarding1Title, subtitle: l10n.onboarding1Subtitle),
      (title: l10n.onboarding2Title, subtitle: l10n.onboarding2Subtitle),
      (title: l10n.onboarding3Title, subtitle: l10n.onboarding3Subtitle),
    ];
    final step = steps[_currentStep];
    final isLast = _currentStep == steps.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text(
                  l10n.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Minh hoạ trung tâm.
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: GlassTokens.durationSlow,
                    switchInCurve: GlassTokens.curve,
                    switchOutCurve: Curves.easeIn,
                    child: GlassContainer(
                      key: ValueKey(_currentStep),
                      radius: AppRadius.hero + 8,
                      shadows: GlassTokens.glow(accent, intensity: 0.35),
                      child: SizedBox.square(
                        dimension: 160,
                        child: Icon(
                          _icons[_currentStep],
                          size: 72,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Card nội dung kính.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: GlassContainer(
                  radius: AppRadius.hero,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  shadows: GlassTokens.shadowSoft,
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              step.subtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Progress pills.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(steps.length, (i) {
                          final isActive = i == _currentStep;
                          return AnimatedContainer(
                            duration: GlassTokens.durationMed,
                            curve: GlassTokens.curve,
                            width: isActive ? 32 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: isActive
                                  ? accent
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.2,
                                    ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      AppButton(
                        label: isLast
                            ? l10n.completeSetup
                            : (_currentStep == 0
                                  ? l10n.getStarted
                                  : l10n.continueAction),
                        icon: isLast
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: _handleNext,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          l10n.alreadyHaveAccount,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.screen,
                ),
                child: Text(
                  l10n.termsFooter,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
