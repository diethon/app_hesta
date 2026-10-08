import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import 'glass/glass_card.dart';

/// Thẻ mặc định của app — nay là alias mỏng trên [GlassCard] để mọi
/// màn dùng chung ngôn ngữ kính.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.active = false,
    this.radius = AppRadius.card,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool active;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      onTap: onTap,
      active: active,
      radius: radius,
      child: child,
    );
  }
}
