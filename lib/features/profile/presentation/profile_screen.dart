import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../authentication/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = session?.name ?? 'Alex';
    final email = session?.email ?? 'alex@syna.local';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 68,
            flexibleSpace: GlassAppBar(centerTitle: false, title: l10n.profile),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.navClearance,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileHeroCard(name: name, email: email),
                const SizedBox(height: AppSpacing.lg),

                _SettingsGroup(
                  title: l10n.groupAccount,
                  items: [
                    _SettingsItem(
                      icon: Icons.notifications_outlined,
                      label: l10n.notifications,
                      onTap: () => context.go('/profile/notifications'),
                    ),
                    _SettingsItem(
                      icon: Icons.settings_outlined,
                      label: l10n.settings,
                      onTap: () => context.go('/profile/settings'),
                    ),
                    _SettingsItem(
                      icon: Icons.language_outlined,
                      label: l10n.language,
                      trailing: GlassStatusPill(
                        label: l10n.languageName,
                        color: theme.colorScheme.primary,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _SettingsGroup(
                  title: l10n.groupSecurity,
                  items: [
                    _SettingsItem(
                      icon: Icons.privacy_tip_outlined,
                      label: l10n.privacy,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      icon: Icons.security_outlined,
                      label: l10n.securitySettings,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _SettingsGroup(
                  items: [
                    _SettingsItem(
                      icon: Icons.logout_rounded,
                      label: l10n.signOut,
                      color: AppColors.auroraError,
                      showChevron: false,
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    return GlassContainer(
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadows: GlassTokens.shadowSoft,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: GlassTokens.glow(accent, intensity: 0.35),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'PRO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            email,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassStatusPill(label: l10n.homeMember, color: mint),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({this.title, required this.items});
  final String? title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                letterSpacing: 0.8,
              ),
            ),
          ),
        GlassContainer(
          radius: AppRadius.card,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, item) in items.indexed) ...[
                if (index > 0)
                  Divider(
                    height: 0,
                    indent: 56,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                item,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  color ?? theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 15,
                  color: color ?? theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
          ],
        ),
      ),
    );
  }
}
