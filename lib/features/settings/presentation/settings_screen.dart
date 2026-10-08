import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _edgeFirst = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GlassAppBar(title: l10n.settings, onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.navClearance,
              ),
              children: [
                GlassContainer(
                  radius: AppRadius.card,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.router_rounded,
                        title: l10n.edgeFirstTitle,
                        subtitle: l10n.edgeFirstSubtitle,
                        trailing: GlassToggle(
                          value: _edgeFirst,
                          onChanged: (value) =>
                              setState(() => _edgeFirst = value),
                        ),
                      ),
                      Divider(
                        height: 0,
                        indent: 56,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        title: l10n.language,
                        subtitle: l10n.languageName,
                        onTap: () {},
                      ),
                      Divider(
                        height: 0,
                        indent: 56,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.privacyAndData,
                        subtitle: l10n.privacyAndDataSubtitle,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
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
