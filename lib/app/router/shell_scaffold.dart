import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/glass/ambient_background.dart';
import '../../core/widgets/glass/glass_bottom_nav.dart';
import '../../features/camera/data/camera_providers.dart';
import '../../features/camera/presentation/widgets/emergency_sos_dialog.dart';
import '../localization/l10n_extensions.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  BuildContext? _sosDialogContext;
  bool _isSosDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    ref.listen<ActiveFallState>(activeFallControllerProvider, (prev, next) {
      if (next.hasActiveAlert && !_isSosDialogShowing) {
        _isSosDialogShowing = true;
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) {
              _sosDialogContext = dialogCtx;
              return Consumer(
                builder: (context, ref, _) {
                  final current = ref.watch(activeFallControllerProvider);
                  if (!current.hasActiveAlert || current.incident == null) {
                    return const SizedBox.shrink();
                  }
                  return EmergencySosDialog(
                    incident: current.incident!,
                    countdown: current.countdown,
                  );
                },
              );
            },
          ).whenComplete(() {
            _sosDialogContext = null;
            _isSosDialogShowing = false;
          }),
        );
      } else if (!next.hasActiveAlert && _isSosDialogShowing) {
        final dialogCtx = _sosDialogContext;
        if (dialogCtx != null && dialogCtx.mounted) {
          Navigator.of(dialogCtx, rootNavigator: true).pop();
        }
        _sosDialogContext = null;
        _isSosDialogShowing = false;
      }
    });

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
      body: AmbientBackground(child: widget.navigationShell),
      bottomNavigationBar: GlassBottomNav(
        items: items,
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
