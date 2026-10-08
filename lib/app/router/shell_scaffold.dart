import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/glass/ambient_background.dart';
import '../../core/widgets/glass/glass_bottom_nav.dart';
import '../localization/l10n_extensions.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final items = [
      GlassNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.home,
      ),
      GlassNavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: l10n.rooms,
      ),
      GlassNavItem(
        icon: Icons.smart_toy_outlined,
        activeIcon: Icons.smart_toy_rounded,
        label: l10n.assistant,
      ),
      GlassNavItem(
        icon: Icons.bolt_outlined,
        activeIcon: Icons.bolt_rounded,
        label: l10n.energy,
      ),
      GlassNavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: l10n.profile,
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AmbientBackground(child: navigationShell),
      bottomNavigationBar: GlassBottomNav(
        items: items,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
