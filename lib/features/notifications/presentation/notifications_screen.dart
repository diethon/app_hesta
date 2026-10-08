import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../data/notification_providers.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GlassAppBar(
            title: l10n.notifications,
            onBack: () => context.pop(),
            actions: [
              GlassCard(
                onTap: () => ref
                    .read(notificationsControllerProvider.notifier)
                    .markAllRead(),
                radius: AppRadius.pill,
                blur: GlassTokens.blurSm,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                semanticLabel: l10n.markAllRead,
                child: Text(
                  l10n.markAllRead,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: notifications.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  l10n.notificationsLoadError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.notificationsEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(notificationsControllerProvider.notifier)
                      .load(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.lg,
                      AppSpacing.screen,
                      AppSpacing.navClearance,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _NotificationTile(
                        notification: item,
                        onTap: item.read
                            ? null
                            : () => ref
                                  .read(notificationsControllerProvider.notifier)
                                  .markRead(item.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  (IconData, Color) _style(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return switch (notification.type) {
      'AUTOMATION' => (
        Icons.auto_awesome_rounded,
        isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight,
      ),
      'DEVICE' => (Icons.devices_other_rounded, theme.colorScheme.primary),
      'SECURITY' => (Icons.shield_rounded, AppColors.auroraError),
      _ => (Icons.info_outline_rounded, AppColors.orbViolet),
    };
  }

  String _tagLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (notification.type) {
      'AUTOMATION' => l10n.notifTagAutomation,
      'SECURITY' => l10n.tagAlert,
      _ => notification.type,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final (icon, color) = _style(context);
    final time = DateFormat('HH:mm • dd/MM').format(notification.createdAt);
    final isUnread = !notification.read;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        onTap: onTap,
        radius: AppRadius.card,
        active: isUnread,
        blur: GlassTokens.blurSm,
        padding: const EdgeInsets.all(AppSpacing.md),
        shadows: isUnread ? GlassTokens.glow(color, intensity: 0.2) : null,
        semanticLabel: notification.title,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                            boxShadow: GlassTokens.glow(
                              theme.colorScheme.primary,
                              intensity: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          _tagLabel(context),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        time,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
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
