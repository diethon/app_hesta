import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  int _selectedFeed = 0;
  bool _isRecording = false;
  bool _isMicOn = false;
  bool _isLightOn = false;
  late final AnimationController _pulseCtrl;

  static const _feeds = [
    _CameraFeed(
      name: 'Front Door',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBhGLV6cphkaQJHWf_HXbzqowJHIhwkmgFhCpkgPNrxjaDa3hXt-GQceSvX2m5BqrWF-oOCA7PTPwi0UQe0nzfQxGnzdjdIiE-FAbjwkp6o3HNcqqIt1xf0uTQLOlKjenil77Ie6wE5eQd-tTaU0Mjz_aCL3LlCXIzVVp7c93TKQCFfKdE8zMDUQRHDngAWwRbD1n-L5tNGvqx0JFuVWyQYypuColXYzPoIVXrDFgIQxhgfDf7g361jl9zxHVLhbAmyiwYVUFkkOMo',
    ),
    _CameraFeed(
      name: 'Patio',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCQ1_x1G4HbAl31FfgYxdVQPILGDemUvcGgOW59UW61He4TmbKlIRO-Mg3IP_BFU1TUOOpxF0Uer-XMjtPTSBVVTfyvmfsv3kTl25loH_RLGKDrJDMrxHaobJSQAFCp0CDYLcGXO4bjxJAJ_aFV5kmbcY9mg-082SAkC5cEqEleYI7GjtElFEmm_XzF-0RYKk465ateON5AZF1teI1iVWR1rzL7s2jJEE_iKEi2pEmzosH1Fvw6nUiq_e4nTwNuq7qQgSlpbuzaMNc',
    ),
    _CameraFeed(
      name: 'Driveway',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDsz1-oW2GPeI1nHd1El3NfLlycXWA4YhdQn6iiTVp1IOxjeaQJbf1WQSQfP26R8dV-wBR8IKI7JZFEgpS0aw2_JwRyMf9BFGX-kVB3VhG_wAYkVV9E5luVWgqrZWidGhOeRYtKEpitHk3YJA8E-BAIkXCLLju73qN6-8ny32XVecuOMgqMrrAhKPD4lYXAbiEvUoTOVrgzTeBaFS9Zh-UuxdoYZY39J9wWOYr_FkKN7atPVTIXYpSnsEK8c_Dj_hvleLQpGWyK95E',
    ),
    _CameraFeed(
      name: 'Kitchen',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCGT7VC2HBdfPfgW8zLvmWOEp_q3uTQctuNQf3LcuzgaYs3TrLUNk1x6HZAaDbWdPkKs-YDE8aLelpp1y1f1DRv0tz1ejnyvh8v5WZIr8CA7S5TA5_DT4ZV1Wz7m4JuEACklSZM9O4yOKVv_Z6xToe7GgXXJ8hLuVaepF_I_JroTuVXOhzceX5NbmSUqGX_wcGSPWb160RF0sW2LAm1xPAEqm6x1rHTmXlzmiLYo9y3t66NNg7NFe3MUci9sTsYQlyQqMs717KfMrM',
    ),
  ];

  static const _historyEvents = [
    _HistoryEvent(
      title: 'Package Delivery',
      location: 'Front Door',
      time: '10:42',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAJmjg6uhhnkWi0nXsD-3c-Bn9-I2MueacHSVGbz5MoRJ85DdfKyOiX6IvyVvtTKdJZboKQsFqKil2plRUCqMzFkyIUgG-ZpyxKEeoxcgdEVnJVjYHyo5HSxoTPLGz-3RoX3utWjyUiU19VBaXw_e3VXFXsBKGa7QWDKfV-CRBet2mFHILnAWvGe-peP_jo4U_uD9PGpIdo9zFybotne70gJSUeNV4WD8AAVk7ZGC7K9ay-iQWAwDGRdoJNty1PZ1Ag-uJGrRV-siU',
    ),
    _HistoryEvent(
      title: 'Vehicle Detected',
      location: 'Driveway',
      time: '09:15',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBVyJi4El7zDUE13_gjG1D6ceBYSYG8hyl4ttIlqECfzWbHlns6zlkJnw5s3yF8pfF9lGOzia1eA97NR20G9dfAuDvvS_bURe0ylZ-cdSuZO9KVs_rQE3kBtzb8RnbJNQsTtBBwqv5rXR4o2WkAu37NabnyH4o3_XbVfKerEZAXqtxBX5nIuTsS38nLRsLbxkdkumN8ES6AcMod-ExGmA-yEec8y6tuaNUOBYFRs7v49pDdPhNsju07CtGkW8m7lhyjr2_vthZ74N8',
      highlighted: true,
    ),
    _HistoryEvent(
      title: 'Pet Movement',
      location: 'Patio',
      time: '03:22',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBK0bX2moALZ8Ls8ByJx5N-yWA3N8xBwc7Qny2QXfFYJPfnDQrbcMPhzeiYiM6rREkey3z3HmB_NZ-vX91lgPhNYIgG4v2W4rZQzycGDGeAAoZlZKuzoADCPNCgieJ0prxa8yqnxyjMzQXbwALzGZZg_A58R5Q1I6hIWBoVuN1DbbkhGQvDz58tnVBsn8DyeQ__h1MlPP8mMIhcV-AiI404NRXrue48e7DWdp-WAgOshKB2VuluVwkOPzKMzyVVUs3AMD4Va2c0TVc',
    ),
    _HistoryEvent(
      title: 'General Activity',
      location: 'Kitchen',
      time: 'Yesterday',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDyqO20ARNsS-gSeO_Fodyq_lSuGRzGXx9y9L7IlQiJY7gPAUy8RSpeJJgBd_Vru2pcUNEtzs833gT4uv9WoUf_sdIB87-6swwUiz_M50c9zmj7-_oQMJYC9OPu-GJhn2S6oqQyPTbgo9ef4JFKD3QVWgfh3snsCzJ13LGldaFXQstWJHSUFz219y4mw198nMV7nXkEvUWnaoIJ0GISqLnw5TK9lNLeDiDwGjiEnIaDbKB7GsBQFGouinshkE5TWwyVGT1_m2qM2Eo',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final feed = _feeds[_selectedFeed];

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
            flexibleSpace: GlassAppBar(
              title: l10n.camera,
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
                _MainFeedPlayer(
                  feed: feed,
                  pulseAnimation: _pulseCtrl,
                  isRecording: _isRecording,
                ),
                const SizedBox(height: AppSpacing.md),

                // Hàng thumbnail chuyển camera.
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: _feeds.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return _FeedThumbnail(
                        feed: _feeds[index],
                        selected: index == _selectedFeed,
                        onTap: () => setState(() => _selectedFeed = index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Cụm nút điều khiển kính.
                Row(
                  children: [
                    Expanded(
                      child: _CameraAction(
                        icon: Icons.photo_camera_outlined,
                        label: l10n.snapshot,
                        onTap: () => HapticFeedback.mediumImpact(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CameraAction(
                        icon: _isRecording
                            ? Icons.stop_circle_outlined
                            : Icons.fiber_manual_record_rounded,
                        label: l10n.record,
                        active: _isRecording,
                        activeColor: AppColors.auroraError,
                        onTap: () =>
                            setState(() => _isRecording = !_isRecording),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CameraAction(
                        icon: _isMicOn
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        label: l10n.talk,
                        active: _isMicOn,
                        onTap: () => setState(() => _isMicOn = !_isMicOn),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CameraAction(
                        icon: _isLightOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        label: l10n.spotlight,
                        active: _isLightOn,
                        activeColor: AppColors.auroraWarning,
                        onTap: () => setState(() => _isLightOn = !_isLightOn),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Timeline sự kiện.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.cameraEvents,
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
                ..._historyEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _EventCard(event: event),
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

// ─────────────────────────────────────────────────────────────────────
// Khung feed live: bo góc lớn + overlay kính (LIVE, timestamp, tên)
// ─────────────────────────────────────────────────────────────────────
class _MainFeedPlayer extends StatelessWidget {
  const _MainFeedPlayer({
    required this.feed,
    required this.pulseAnimation,
    required this.isRecording,
  });

  final _CameraFeed feed;
  final Animation<double> pulseAnimation;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = DateFormat('HH:mm:ss • dd/MM').format(DateTime.now());

    return GlassContainer(
      radius: AppRadius.hero,
      padding: EdgeInsets.zero,
      shadows: GlassTokens.shadowSoft,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: GlassTokens.durationMed,
              child: CachedNetworkImage(
                key: ValueKey(feed.imageUrl),
                imageUrl: feed.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: Colors.black),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: Colors.black,
                  child: Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 40,
                  ),
                ),
              ),
            ),
            // LIVE badge (kính).
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: GlassContainer(
                radius: AppRadius.pill,
                blur: GlassTokens.blurSm,
                fill: Colors.black.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (context, child) => Opacity(
                        opacity: 0.5 + pulseAnimation.value * 0.5,
                        child: child,
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.auroraError,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'LIVE • 4K',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tên camera (kính).
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: GlassContainer(
                radius: AppRadius.pill,
                blur: GlassTokens.blurSm,
                fill: Colors.black.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  feed.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Timestamp + fullscreen (kính) dưới đáy.
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassContainer(
                    radius: AppRadius.pill,
                    blur: GlassTokens.blurSm,
                    fill: Colors.black.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRecording) ...[
                          const Icon(
                            Icons.fiber_manual_record_rounded,
                            color: AppColors.auroraError,
                            size: 12,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          timestamp,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassIconButton(
                    icon: Icons.fullscreen_rounded,
                    size: 36,
                    iconColor: Colors.white,
                    onTap: () {},
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

class _FeedThumbnail extends StatelessWidget {
  const _FeedThumbnail({
    required this.feed,
    required this.selected,
    required this.onTap,
  });

  final _CameraFeed feed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GlassCard(
      onTap: onTap,
      radius: AppRadius.lg,
      padding: EdgeInsets.zero,
      active: selected,
      borderGradient: selected
          ? LinearGradient(colors: [accent, accent.withValues(alpha: 0.4)])
          : null,
      shadows: selected ? GlassTokens.glow(accent, intensity: 0.4) : null,
      semanticLabel: feed.name,
      child: SizedBox(
        width: 104,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: feed.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => ColoredBox(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              errorWidget: (_, __, ___) => ColoredBox(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              left: AppSpacing.xs + 2,
              bottom: AppSpacing.xs + 2,
              child: Text(
                feed.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraAction extends StatelessWidget {
  const _CameraAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = activeColor ?? theme.colorScheme.primary;

    return GlassCard(
      onTap: onTap,
      radius: AppRadius.lg,
      active: active,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      shadows: active ? GlassTokens.glow(tint, intensity: 0.4) : null,
      semanticLabel: label,
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: active
                ? tint
                : theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: active
                  ? tint
                  : theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final _HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GlassCard(
      onTap: () {},
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.sm),
      active: event.highlighted,
      shadows: event.highlighted
          ? GlassTokens.glow(accent, intensity: 0.25)
          : null,
      semanticLabel: event.title,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 88,
              height: 60,
              child: CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.location,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            event.time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraFeed {
  const _CameraFeed({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;
}

class _HistoryEvent {
  const _HistoryEvent({
    required this.title,
    required this.location,
    required this.time,
    required this.imageUrl,
    this.highlighted = false,
  });

  final String title;
  final String location;
  final String time;
  final String imageUrl;
  final bool highlighted;
}
