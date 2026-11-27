import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

/// Bottom sheet nổi chuẩn Midnight Aurora, bọc [GlassContainer] và thanh kéo.
class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({
    required this.child,
    this.padding,
    this.maxHeightFactor = 0.88,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          viewInsets + AppSpacing.md,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: GlassContainer(
            radius: AppRadius.hero,
            blur: GlassTokens.blurLg,
            fill: isDark
                ? AppColors.auroraCanvasMid.withValues(alpha: 0.92)
                : AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
            shadows: GlassTokens.shadowSoft,
            padding:
                padding ??
                const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.22,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog xác nhận / nhập liệu dùng bề mặt kính Midnight Aurora đồng nhất.
/// Các nút trong [actions] được dàn đều theo hàng ngang.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    required this.title,
    required this.content,
    required this.actions,
    this.subtitle,
    this.icon,
    this.iconColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = iconColor ?? theme.colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.lg,
      ),
      child: GlassContainer(
        radius: AppRadius.card,
        blur: GlassTokens.blurLg,
        fill: isDark
            ? AppColors.auroraCanvasMid.withValues(alpha: 0.94)
            : AppColors.surfaceContainerLowest.withValues(alpha: 0.96),
        shadows: GlassTokens.shadowSoft,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: tint.withValues(alpha: 0.25)),
                      ),
                      child: Icon(icon, color: tint, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              content,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dòng tùy chọn đồng bộ trong [GlassBottomSheet].
class GlassOptionTile extends StatelessWidget {
  const GlassOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color,
    this.titleColor,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: tint.withValues(alpha: 0.24)),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: titleColor ?? theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decoration ô nhập liệu chuẩn hệ Midnight Aurora cho cả Light/Dark mode.
InputDecoration glassInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? suffixText,
  Color? accentColor,
  EdgeInsetsGeometry? contentPadding,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final effectiveAccent = accentColor ?? theme.colorScheme.primary;
  final borderColor = GlassTokens.borderSolid(theme.brightness);

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    suffixText: suffixText,
    suffixStyle: theme.textTheme.labelLarge?.copyWith(
      color: effectiveAccent,
      fontWeight: FontWeight.w700,
    ),
    labelStyle: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
    ),
    hintStyle: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
    ),
    counterStyle: theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    ),
    filled: true,
    fillColor: isDark
        ? GlassTokens.fillDarkActive
        : AppColors.surfaceContainerLow,
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 6,
        ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: effectiveAccent, width: 1.5),
    ),
  );
}
