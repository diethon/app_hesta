import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import 'glass_container.dart';

/// Nút tròn kính (back / action) dùng trong [GlassAppBar] và các overlay.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconColor,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: GlassContainer(
          shape: BoxShape.circle,
          blur: GlassTokens.blurSm,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: size * 0.5,
              color: iconColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// App bar kính trong suốt: nút back tròn + tiêu đề + actions tròn.
/// Dùng trong [Scaffold.appBar] hoặc thả nổi trong Stack qua
/// [GlassAppBar.floating].
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    this.title,
    this.subtitle,
    this.leading,
    this.onBack,
    this.actions = const [],
    this.transparent = false,
    this.centerTitle = true,
    super.key,
  });

  /// Tiêu đề dạng widget tự do (ưu tiên hơn [title]/[subtitle] dạng text).
  final Widget? leading;
  final String? title;
  final String? subtitle;

  /// Có [onBack] → hiện nút back tròn kính.
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// true → không vẽ nền kính chạy ngang (chỉ còn các nút tròn nổi).
  final bool transparent;
  final bool centerTitle;

  static const double _height = 68;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleBlock = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
      ],
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (onBack != null)
            GlassIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else if (leading != null)
            leading!,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: centerTitle ? Center(child: titleBlock) : titleBlock,
            ),
          ),
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: action,
            ),
        ],
      ),
    );

    final bar = SafeArea(
      bottom: false,
      child: SizedBox(height: _height, child: row),
    );

    if (transparent) return bar;

    return GlassContainer(
      radius: 0,
      blur: GlassTokens.blurLg,
      borderGradient: const LinearGradient(
        colors: [Colors.transparent, Colors.transparent],
      ),
      child: bar,
    );
  }
}
