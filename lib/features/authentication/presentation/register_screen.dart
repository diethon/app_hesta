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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController(text: 'Alex');
  final _emailController = TextEditingController(text: 'alex@syna.local');
  final _passwordController = TextEditingController(text: '123456');
  final _confirmController = TextEditingController(text: '123456');
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.go('/login'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: GlassTokens.glow(accent, intensity: 0.5),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          l10n.appName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      l10n.joinApp,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.registerSubtitle,
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
                            label: l10n.fullName,
                            controller: _nameController,
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: l10n.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 380;
                              final passwordField = AppTextField(
                                label: l10n.password,
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                textInputAction: TextInputAction.next,
                              );
                              final confirmField = AppTextField(
                                label: l10n.confirmPassword,
                                controller: _confirmController,
                                obscureText: true,
                                prefixIcon: Icons.lock_reset_rounded,
                                textInputAction: TextInputAction.done,
                              );
                              if (isWide) {
                                return Row(
                                  children: [
                                    Expanded(child: passwordField),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(child: confirmField),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  passwordField,
                                  const SizedBox(height: AppSpacing.md),
                                  confirmField,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GlassToggle(
                                value: _termsAccepted,
                                size: 0.85,
                                onChanged: (value) =>
                                    setState(() => _termsAccepted = value),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  l10n.agreeToTerms,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.65),
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
                            label: l10n.createAccount,
                            icon: Icons.arrow_forward_rounded,
                            isLoading: auth.isSubmitting,
                            onPressed: _termsAccepted
                                ? () {
                                    ref
                                        .read(authControllerProvider.notifier)
                                        .register(
                                          _nameController.text.trim(),
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        );
                                  }
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          Divider(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${l10n.alreadyHaveAccountShort} ',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/login'),
                                  child: Text(
                                    l10n.signIn,
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
