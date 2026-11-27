import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../../core/services/websocket_service.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
import '../../authentication/presentation/auth_controller.dart';
import '../../home/data/home_providers.dart';
import '../domain/camera_repository.dart';
import '../domain/fall_incident.dart';
import 'api_camera_repository.dart';
import 'mock_camera_repository.dart';

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  if (kUseMockData) {
    return MockCameraRepository();
  }
  return ApiCameraRepository(ref.watch(cloudApiClientProvider));
});

class ActiveFallState {
  const ActiveFallState({
    this.incident,
    this.countdown = 30,
    this.aiStatus,
    this.isMuted = false,
    this.demoVideos = const [],
    this.isSelectingVideo = false,
  });

  final FallIncident? incident;
  final int countdown;
  final AiStatus? aiStatus;
  final bool isMuted;
  final List<DemoVideoItem> demoVideos;
  final bool isSelectingVideo;

  bool get hasActiveAlert => incident != null && incident!.isActive;

  ActiveFallState copyWith({
    FallIncident? incident,
    int? countdown,
    AiStatus? aiStatus,
    bool? isMuted,
    List<DemoVideoItem>? demoVideos,
    bool? isSelectingVideo,
    bool clearIncident = false,
  }) {
    return ActiveFallState(
      incident: clearIncident ? null : (incident ?? this.incident),
      countdown: countdown ?? this.countdown,
      aiStatus: aiStatus ?? this.aiStatus,
      isMuted: isMuted ?? this.isMuted,
      demoVideos: demoVideos ?? this.demoVideos,
      isSelectingVideo: isSelectingVideo ?? this.isSelectingVideo,
    );
  }
}

class ActiveFallController extends StateNotifier<ActiveFallState> {
  ActiveFallController(this._repository, this._ref)
    : super(const ActiveFallState()) {
    _initListeners();
  }

  final CameraRepository _repository;
  final Ref _ref;
  Timer? _countdownTimer;
  Timer? _aiPollTimer;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  String get videoFeedUrl => _repository.videoFeedUrl;

  void _initListeners() {
    // 1. Subscribe to backend STOMP WebSocket: /user/topic/fall
    if (!kUseMockData && _ref.read(authControllerProvider).isAuthenticated) {
      final ws = _ref.read(webSocketServiceProvider);
      _wsSubscription = ws.subscribeJson('/user/topic/fall').listen((event) {
        final incident = FallIncident.fromJson(event);
        if (incident.isActive) {
          triggerAlert(incident);
        } else {
          _countdownTimer?.cancel();
          if (mounted) {
            state = state.copyWith(clearIncident: true, countdown: 30);
          }
        }
      });
      unawaited(syncActiveIncidents());
    }
  }

  Future<void> syncActiveIncidents() async {
    try {
      final homeId = _ref.read(currentHomeIdProvider);
      final active = await _repository.getActiveIncidents(homeId);
      if (!mounted) {
        return;
      }
      if (active.isNotEmpty && state.incident == null) {
        triggerAlert(active.first);
      }
    } catch (_) {
      // Offline / unauthenticated fallback
    }
  }

  void startAiHudPolling() {
    if (_aiPollTimer != null) {
      return;
    }
    unawaited(_pollAiOnce());
    _aiPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_pollAiOnce());
    });
  }

  void stopAiHudPolling() {
    _aiPollTimer?.cancel();
    _aiPollTimer = null;
  }

  Future<void> _pollAiOnce() async {
    final status = await _repository.checkAiStatus();
    if (!mounted || status == null) {
      return;
    }
    state = state.copyWith(aiStatus: status);
    if (status.alert && state.incident == null) {
      final detected = FallIncident(
        id: 'ai-fall-${DateTime.now().millisecondsSinceEpoch}',
        roomName: 'Camera Phòng Khách',
        incidentType: status.incidentType != 'NONE'
            ? status.incidentType
            : 'ACCIDENTAL_FALL',
        state: 'DETECTED',
        confidenceScore: 0.96,
        countdownRemainingSec: 30,
        metrics: status.metrics,
        snapshotUrl: videoFeedUrl.isNotEmpty
            ? videoFeedUrl
            : 'http://10.0.2.2:5000/video_feed',
      );
      triggerAlert(detected);
    }
  }

  void triggerAlert(FallIncident incident) {
    _countdownTimer?.cancel();
    state = state.copyWith(
      incident: incident,
      countdown: incident.countdownRemainingSec > 0
          ? incident.countdownRemainingSec
          : 30,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (state.countdown <= 1) {
        timer.cancel();
        if (state.incident != null) {
          state = state.copyWith(
            countdown: 0,
            incident: state.incident!.copyWith(state: 'ESCALATED_SOS'),
          );
        }
      } else {
        state = state.copyWith(countdown: state.countdown - 1);
      }
    });
  }

  Future<void> dismiss() async {
    _countdownTimer?.cancel();
    final incId = state.incident?.id;
    if (incId != null) {
      await _repository.dismissIncident(incId);
    } else {
      await _repository.dismissAiLocal();
    }
    if (mounted) {
      state = state.copyWith(clearIncident: true, countdown: 30);
    }
  }

  Future<void> acknowledge() async {
    final incId = state.incident?.id;
    if (incId != null) {
      await _repository.acknowledgeIncident(incId);
      if (mounted && state.incident != null) {
        state = state.copyWith(
          incident: state.incident!.copyWith(state: 'ACKNOWLEDGED'),
        );
      }
    }
  }

  Future<void> resolve({String note = 'Đã hỗ trợ cấp cứu an toàn'}) async {
    _countdownTimer?.cancel();
    final incId = state.incident?.id;
    if (incId != null) {
      await _repository.resolveIncident(incId, note: note);
    } else {
      await _repository.dismissAiLocal();
    }
    if (mounted) {
      state = state.copyWith(clearIncident: true, countdown: 30);
    }
  }

  Future<void> loadDemoVideos() async {
    final videos = await _repository.getDemoVideos();
    if (mounted) {
      state = state.copyWith(demoVideos: videos);
    }
  }

  Future<bool> selectVideo(String videoId) async {
    state = state.copyWith(isSelectingVideo: true);
    final ok = await _repository.selectDemoVideo(videoId);
    final videos = await _repository.getDemoVideos();
    if (mounted) {
      state = state.copyWith(isSelectingVideo: false, demoVideos: videos);
    }
    return ok;
  }

  Future<void> triggerDemoFall() async {
    final homeId = _ref.read(currentHomeIdProvider) ?? 'home-mock-1';
    final demo = FallIncident(
      id: 'demo-fall-${DateTime.now().millisecondsSinceEpoch}',
      homeId: homeId,
      roomName: 'Camera Phòng Khách',
      incidentType: 'ACCIDENTAL_FALL',
      state: 'DETECTED',
      confidenceScore: 0.98,
      countdownRemainingSec: 30,
      detectedAt: DateTime.now().toIso8601String(),
      metrics: const FallMetrics(
        vNorm: 2.15,
        accelG: 3.1,
        spineAngle: 85.0,
        motionEnergy: 6.2,
      ),
      snapshotUrl: videoFeedUrl.isNotEmpty
          ? videoFeedUrl
          : 'http://10.0.2.2:5000/video_feed',
    );
    await _repository.triggerDemoFall();
    triggerAlert(demo);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _aiPollTimer?.cancel();
    unawaited(_wsSubscription?.cancel());
    super.dispose();
  }
}

final activeFallControllerProvider =
    StateNotifierProvider<ActiveFallController, ActiveFallState>((ref) {
      final repo = ref.watch(cameraRepositoryProvider);
      return ActiveFallController(repo, ref);
    });
