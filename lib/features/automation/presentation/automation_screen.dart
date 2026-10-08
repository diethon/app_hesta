import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/state_views.dart';

/// Loại trigger của một rule — quyết định badge hiển thị.
enum _TriggerKind { time, sensor, location }

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final List<_AutomationRule> _rules = [
    const _AutomationRule(
      id: 'sunset',
      title: 'Sunset Routine',
      subtitle: 'Daily • Local Time',
      icon: Icons.wb_twilight_rounded,
      trigger: _TriggerKind.time,
      action: 'Close Living Blinds',
      isActive: true,
    ),
    const _AutomationRule(
      id: 'arrive-home',
      title: 'Arrive Home',
      subtitle: 'Geofence • < 50m',
      icon: Icons.home_work_rounded,
      trigger: _TriggerKind.location,
      action: 'Unlock Door & AC 23°C',
      isActive: true,
    ),
    const _AutomationRule(
      id: 'motion-lights',
      title: 'Night Motion Lights',
      subtitle: 'Hallway sensor',
      icon: Icons.sensors_rounded,
      trigger: _TriggerKind.sensor,
      action: 'Hallway lights 30%',
      isActive: false,
    ),
  ];

  final List<_QuickScene> _scenes = const [
    _QuickScene(
      name: 'Movie Night',
      deviceCount: 8,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDMi27uI6y9g_0wDJfnJWka8_Nx1V2BAqqKR45R9AR6SeDbKiCNcQKcemA0NjWVgcQ1X3F0P0Aipgw7eyZbxo96mR555atUAof-iYHm1wBM6GHHNvmihitO9I8KxJ32vjBOgUjyXgmNpwvmRBZ92uHaO9P9byytqY6ADL7vAmWdm1a9cBein4amxYzQl_7GLEcltPExr0wxJxmkPL6DNvVWO5C0PHRIxV2Rn6YQJowkehu4hnVSmB7xERlO-Rx6qdkHFwYUiD8kSDE',
    ),
    _QuickScene(
      name: 'Good Night',
      deviceCount: 12,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDfCpPPnIOau7Z1M7jvgN7xGJdt3vaUosuj2g672sqA7gEhfb8omcosmjg__d2qphBthhIQql7O-sxA8dN7s8ofY3vHEFPzkSSEdOtiMcMzrfsNgXYh7n6FWy7zAHoIuzsiwrWZj8aKkeZrEK0RV9X4nbCjC49opQgRiIUjNEcJGDu-XqI523EqvTT4gqDPpZpHPGgu_kSFQaC6ttZHJztJvn5q1tQo8WYNwi0g6q8qec0X_qXmTu3CNxqmEGA9L82erj_llZqIOlI',
    ),
    _QuickScene(
      name: 'Focus Mode',
      deviceCount: 4,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDQmzhmmlIBGEdX7iMmI6ugkORwxTLjxE65GmB3FXT5tRs4NN5x1fv5A_exuuhOZ62h1E-REpc_Ds3cEtv88rk2CKtRIRfo5wbgQMJmXVt7mFYrVsJPxGJi4k_5KqbVwA9mhBg1lrZ5o2qi9nNA4kxoekMM9mWC8i4uKcUv7tKcr-RB9xLcVtmPEUhB4PHlxhAnSa-3xHer26WqkaUe9zy01IHCBT0MnhhtkphoXp6XJK4eTMGS5OGmR5ku5ckhytMg9u-maKc-dsU',
    ),
  ];

  void _toggleRule(String id) {
    setState(() {
      final index = _rules.indexWhere((rule) => rule.id == id);
      _rules[index] = _rules[index].copyWith(isActive: !_rules[index].isActive);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl * 2),
        child: _CreateRuleFab(onPressed: () {}),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 68,
            flexibleSpace: GlassAppBar(
              title: l10n.automations,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                GlassIconButton(
                  icon: Icons.notifications_outlined,
                  tooltip: l10n.notifications,
                  onTap: () => context.go('/profile/notifications'),
                ),
              ],
            ),
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
                // Header
                Text(
                  l10n.management.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.automations, style: theme.textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.lg),

                // IF-THEN builder
                GlassContainer(
                  radius: AppRadius.hero,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 520;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: _IfSection()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xl,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 24,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            const Expanded(child: _ThenSection()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          const _IfSection(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 24,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          const _ThenSection(),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Active rules
                Text(l10n.activeRules, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                if (_rules.isEmpty)
                  SizedBox(
                    height: 200,
                    child: EmptyView(
                      message: l10n.noAutomationsYet,
                      icon: Icons.auto_awesome_outlined,
                    ),
                  )
                else
                  ..._rules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RuleCard(
                        rule: rule,
                        onToggle: () => _toggleRule(rule.id),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),

                // Quick scenes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.quickScenes,
                      style: theme.textTheme.headlineMedium,
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        l10n.viewAll,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 224,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: _scenes.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      if (index == _scenes.length) {
                        return const _NewSceneCard();
                      }
                      return _SceneCard(scene: _scenes[index]);
                    },
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút tạo rule nổi (FAB kính accent).
class _CreateRuleFab extends StatelessWidget {
  const _CreateRuleFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = theme.colorScheme.primary;

    return GlassCard(
      onTap: onPressed,
      radius: AppRadius.pill,
      fill: accent,
      shadows: GlassTokens.glow(accent, intensity: 0.8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      semanticLabel: l10n.createNew,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.createNew,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IfSection extends StatelessWidget {
  const _IfSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionBadge(label: 'IF', color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.triggerOccurs,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _TriggerTile(icon: Icons.schedule_rounded, label: l10n.triggerTime),
        const SizedBox(height: AppSpacing.sm),
        _TriggerTile(icon: Icons.near_me_rounded, label: l10n.triggerLocation),
        const SizedBox(height: AppSpacing.sm),
        _TriggerTile(
          icon: Icons.sensors_rounded,
          label: l10n.triggerDeviceState,
        ),
      ],
    );
  }
}

class _ThenSection extends StatelessWidget {
  const _ThenSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionBadge(label: 'THEN', color: mint),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.executeAction,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _TriggerTile(
          icon: Icons.palette_rounded,
          label: l10n.actionScenes,
          accentColor: mint,
        ),
        const SizedBox(height: AppSpacing.sm),
        _TriggerTile(
          icon: Icons.settings_remote_rounded,
          label: l10n.actionControlDevice,
          accentColor: mint,
        ),
      ],
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _TriggerTile extends StatelessWidget {
  const _TriggerTile({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    return GlassCard(
      onTap: () {},
      radius: AppRadius.lg,
      blur: GlassTokens.blurSm,
      padding: const EdgeInsets.all(AppSpacing.md),
      semanticLabel: label,
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Badge nhỏ hiển thị loại trigger trên rule card.
class _TriggerBadge extends StatelessWidget {
  const _TriggerBadge({required this.kind});

  final _TriggerKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, label, color) = switch (kind) {
      _TriggerKind.time => (
        Icons.schedule_rounded,
        l10n.triggerTime,
        AppColors.auroraWarning,
      ),
      _TriggerKind.sensor => (
        Icons.sensors_rounded,
        l10n.triggerDeviceState,
        AppColors.orbTeal,
      ),
      _TriggerKind.location => (
        Icons.near_me_rounded,
        l10n.triggerLocation,
        AppColors.orbViolet,
      ),
    };

    return GlassStatusPill(icon: icon, label: label, color: color);
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.onToggle});

  final _AutomationRule rule;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = theme.colorScheme.primary;

    return GlassCard(
      onTap: () {},
      radius: AppRadius.hero,
      active: rule.isActive,
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadows: rule.isActive ? GlassTokens.glow(accent, intensity: 0.2) : null,
      child: AnimatedOpacity(
        duration: GlassTokens.durationMed,
        opacity: rule.isActive ? 1.0 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(rule.icon, color: accent, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        rule.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GlassToggle(value: rule.isActive, onChanged: (_) => onToggle()),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _TriggerBadge(kind: rule.trigger),
                GlassStatusPill(
                  icon: Icons.play_arrow_rounded,
                  label: rule.action,
                  color: theme.brightness == Brightness.dark
                      ? AppColors.auroraMint
                      : AppColors.auroraMintOnLight,
                ),
                if (rule.isActive)
                  GlassStatusPill(
                    label: l10n.statusActive,
                    color: theme.brightness == Brightness.dark
                        ? AppColors.auroraMint
                        : AppColors.auroraMintOnLight,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneCard extends StatefulWidget {
  const _SceneCard({required this.scene});

  final _QuickScene scene;

  @override
  State<_SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends State<_SceneCard> {
  bool _activated = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;

    return GlassCard(
      onTap: () {
        setState(() => _activated = true);
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _activated = false);
        });
      },
      radius: AppRadius.hero,
      padding: EdgeInsets.zero,
      semanticLabel: widget.scene.name,
      child: SizedBox(
        width: 192,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.scene.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => ColoredBox(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              errorWidget: (_, __, ___) => ColoredBox(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: AnimatedSwitcher(
                duration: GlassTokens.durationFast,
                child: Icon(
                  _activated
                      ? Icons.check_circle_rounded
                      : Icons.play_circle_outline_rounded,
                  key: ValueKey(_activated),
                  color: _activated
                      ? mint
                      : Colors.white.withValues(alpha: 0.5),
                  size: 28,
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.scene.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.devicesCount(widget.scene.deviceCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewSceneCard extends StatelessWidget {
  const _NewSceneCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return GlassCard(
      onTap: () {},
      radius: AppRadius.hero,
      padding: EdgeInsets.zero,
      semanticLabel: l10n.newScene,
      child: SizedBox(
        width: 192,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 32,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.newScene,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomationRule {
  const _AutomationRule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trigger,
    required this.action,
    required this.isActive,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final _TriggerKind trigger;
  final String action;
  final bool isActive;

  _AutomationRule copyWith({bool? isActive}) {
    return _AutomationRule(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      trigger: trigger,
      action: action,
      isActive: isActive ?? this.isActive,
    );
  }
}

class _QuickScene {
  const _QuickScene({
    required this.name,
    required this.deviceCount,
    required this.imageUrl,
  });

  final String name;
  final int deviceCount;
  final String imageUrl;
}
