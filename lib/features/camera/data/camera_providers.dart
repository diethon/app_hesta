import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_client.dart';
import '../../../core/services/websocket_service.dart';
import '../../authentication/data/auth_providers.dart' show kUseMockData;
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
  });

  final FallIncident? incident;
  final int countdown;
  final AiStatus? aiStatus;
  final bool isMuted;

  bool get hasActiveAlert => incident != null && incident!.isActive;

  ActiveFallState copyWith({
    FallIncident? incident,
    int? countdown,
    AiStatus? aiStatus,
    bool? isMuted,
    bool clearIncident = false,
  }) {
    return ActiveFallState(
      incident: clearIncident ? null : (incident ?? this.incident),
      countdown: countdown ?? this.countdown,
      aiStatus: aiStatus ?? this.aiStatus,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class ActiveFallController extends StateNotifier<ActiveFallState> {
  ActiveFallController(this._repository, this._ref)
    : super(const ActiveFallState()) {
    _initListeners();
    _startAiPolling();
  }

  final CameraRepository _repository;
  final Ref _ref;
  Timer? _countdownTimer;
  Timer? _aiPollTimer;
  StreamSubscription? _wsSubscription;

  void _initListeners() {
    // 1. Subscribe to backend STOMP WebSocket: /user/topic/fall
    if (!kUseMockData) {
      final ws = _ref.read(webSocketServiceProvider);
      _wsSubscription = ws.subscribeJson('/user/topic/fall').listen((event) {
        final incident = FallIncident.fromJson(event);
        if (incident.isActive) {
          triggerAlert(incident);
        } else {
          dismiss();
        }
      });
    }
  }

  void _startAiPolling() {
    _aiPollTimer?.cancel();
    _aiPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final status = await _repository.checkAiStatus();
      if (status != null) {
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
            snapshotUrl: 'http://10.0.2.2:5000/video_feed',
          );
          triggerAlert(detected);
        }
      }
    });
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
    state = state.copyWith(clearIncident: true, countdown: 30);
  }

  Future<void> acknowledge() async {
    final incId = state.incident?.id;
    if (incId != null) {
      await _repository.acknowledgeIncident(incId);
      if (state.incident != null) {
        state = state.copyWith(
          incident: state.incident!.copyWith(state: 'ACKNOWLEDGED'),
        );
      }
    }
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
      snapshotUrl: 'http://10.0.2.2:5000/video_feed',
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
    _wsSubscription?.cancel();
    super.dispose();
  }
}

final activeFallControllerProvider =
    StateNotifierProvider<ActiveFallController, ActiveFallState>((ref) {
      final repo = ref.watch(cameraRepositoryProvider);
      return ActiveFallController(repo, ref);
    });
