import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/glass/glass.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'test@gmail.com');
  final _passwordController = TextEditingController(text: '123123123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo mark
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: GlassTokens.glow(accent, intensity: 0.7),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      l10n.welcomeBack,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    GlassContainer(
                      radius: AppRadius.xl,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      shadows: GlassTokens.shadowSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            label: l10n.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline_rounded,
                            hintText: 'test@gmail.com',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Stack(
                            children: [
                              AppTextField(
                                label: l10n.password,
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                hintText: '••••••••',
                                textInputAction: TextInputAction.done,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    l10n.forgotPassword,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              auth.errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: l10n.signIn,
                            isLoading: auth.isSubmitting,
                            onPressed: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .login(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  child: Text(
                                    l10n.orContinueWith.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GlassCard(
                            onTap: () {},
                            radius: AppRadius.lg,
                            blur: GlassTokens.blurSm,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            semanticLabel: l10n.signInWithFaceId,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.face_rounded,
                                  color: accent,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  l10n.signInWithFaceId,
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${l10n.newToApp} ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text(
                              l10n.createAccount,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
