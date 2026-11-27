import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_slider.dart';
import '../data/device_group_providers.dart';
import '../domain/device_group.dart';

class DeviceGroupStrip extends ConsumerWidget {
  const DeviceGroupStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupState = ref.watch(deviceGroupsControllerProvider);
    final groups = groupState.groups;

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NHÓM THIẾT BỊ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/groups'),
              child: Text(
                'Xem tất cả',
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
          height: 192,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final group = groups[index];
              return _CompactGroupCard(group: group);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _CompactGroupCard extends ConsumerWidget {
  const _CompactGroupCard({required this.group});

  final DeviceGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final danger = isDark ? AppColors.auroraError : AppColors.error;

    return SizedBox(
      width: 260,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                  child: Icon(Icons.layers_rounded, color: accent, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${group.deviceCount} TB',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_rounded,
                      size: 14,
                      color: AppColors.auroraWarning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Master Dimmer',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  '${group.currentBrightness}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.auroraWarning,
                  ),
                ),
              ],
            ),
            GlassSlider(
              value: (group.currentBrightness / 100).clamp(0.0, 1.0),
              height: 36,
              onChanged: (val) {
                final intVal = (val * 100).round();
                ref
                    .read(deviceGroupsControllerProvider.notifier)
                    .setGroupBrightness(group.id, intVal);
              },
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => ref
                        .read(deviceGroupsControllerProvider.notifier)
                        .toggleGroupPower(group.id, true),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: mint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: mint.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Bật hết',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: mint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: InkWell(
                    onTap: () => ref
                        .read(deviceGroupsControllerProvider.notifier)
                        .toggleGroupPower(group.id, false),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: danger.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Tắt hết',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
