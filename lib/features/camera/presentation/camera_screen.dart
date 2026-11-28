import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../data/camera_providers.dart';
import '../domain/fall_incident.dart';
import 'widgets/mjpeg_live_player.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with SingleTickerProviderStateMixin {
  int _selectedFeed = 0;
  bool _isRecording = false;
  bool _isMicOn = false;
  bool _isLightOn = false;
  int _streamReloadSignal = 0;
  late final AnimationController _pulseCtrl;
  late final ActiveFallController _fallController;

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
    _fallController = ref.read(activeFallControllerProvider.notifier);
    Future.microtask(() {
      _fallController.startAiHudPolling();
      unawaited(_fallController.loadDemoVideos());
    });
  }

  @override
  void dispose() {
    _fallController.stopAiHudPolling();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final feed = _feeds[_selectedFeed];
    final fallState = ref.watch(activeFallControllerProvider);
    final liveStreamUrl = _selectedFeed == 0
        ? _fallController.videoFeedUrl
        : '';

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
                  streamUrl: liveStreamUrl,
                  reloadSignal: _streamReloadSignal,
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
                const SizedBox(height: AppSpacing.md),

                // AI Vision HUD & Demo Trigger
                _AiVisionHud(
                  aiStatus: fallState.aiStatus,
                  demoVideos: fallState.demoVideos,
                  isSelectingVideo: fallState.isSelectingVideo,
                  onSelectVideo: (videoId) async {
                    final ok = await _fallController.selectVideo(videoId);
                    if (!context.mounted) {
                      return;
                    }
                    setState(() {
                      _selectedFeed = 0;
                      _streamReloadSignal++;
                    });
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã gửi chuyển nguồn AI (kiểm tra kết nối Edge AI).',
                          ),
                        ),
                      );
                    }
                  },
                  onTriggerDemo: () {
                    unawaited(_fallController.triggerDemoFall());
                  },
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
    this.streamUrl = '',
    this.reloadSignal = 0,
  });

  final _CameraFeed feed;
  final Animation<double> pulseAnimation;
  final bool isRecording;
  final String streamUrl;
  final int reloadSignal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = DateFormat('HH:mm:ss • dd/MM').format(DateTime.now());
    final fallbackImage = CachedNetworkImage(
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
    );

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
              child: streamUrl.isNotEmpty
                  ? MjpegLivePlayer(
                      key: ValueKey('mjpeg-$streamUrl'),
                      streamUrl: streamUrl,
                      reloadSignal: reloadSignal,
                      fallback: fallbackImage,
                    )
                  : fallbackImage,
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

class _AiVisionHud extends StatelessWidget {
  const _AiVisionHud({
    required this.aiStatus,
    required this.onTriggerDemo,
    this.demoVideos = const [],
    this.isSelectingVideo = false,
    this.onSelectVideo,
  });

  final AiStatus? aiStatus;
  final VoidCallback onTriggerDemo;
  final List<DemoVideoItem> demoVideos;
  final bool isSelectingVideo;
  final ValueChanged<String>? onSelectVideo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final danger = isDark ? AppColors.auroraError : AppColors.error;
    final isOnline = aiStatus?.isOnline ?? true;
    final fps = aiStatus?.fps ?? 30;
    final stateStr = aiStatus?.state ?? 'STANDING';
    final isFallen = stateStr == 'FALLEN';
    final metrics = aiStatus?.metrics ?? const FallMetrics();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline
                      ? mint
                      : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  boxShadow: isOnline
                      ? GlassTokens.glow(mint, intensity: 0.6)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'YOLOv8-Pose AI Engine ($fps FPS)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: (isFallen ? danger : accent).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: (isFallen ? danger : accent).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  isFallen ? 'NGHI VẤN NGÃ' : 'BÌNH THƯỜNG',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isFallen ? danger : accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            children: [
              Expanded(
                child: _HudMetricTile(
                  label: 'Vận tốc chuẩn',
                  value: metrics.vNorm.toStringAsFixed(2),
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HudMetricTile(
                  label: 'Gia tốc',
                  value: '${metrics.accelG.toStringAsFixed(1)}G',
                  color: AppColors.auroraWarning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HudMetricTile(
                  label: 'Góc lưng',
                  value: '${metrics.spineAngle.toStringAsFixed(0)}°',
                  color: isFallen ? danger : mint,
                ),
              ),
            ],
          ),
          if (demoVideos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: demoVideos.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final video = demoVideos[idx];
                  return GlassFilterChip(
                    label: video.name,
                    selected: video.active,
                    onTap: () {
                      if (!isSelectingVideo) {
                        onSelectVideo?.call(video.id);
                      }
                    },
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: danger,
                backgroundColor: danger.withValues(alpha: 0.08),
                side: BorderSide(
                  color: danger.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: onTriggerDemo,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text(
                'Bắn Sự Kiện Ngã Demo (Test SOS 30s)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudMetricTile extends StatelessWidget {
  const _HudMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: GlassTokens.fill(theme.brightness, active: false),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: GlassTokens.borderSolid(theme.brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
