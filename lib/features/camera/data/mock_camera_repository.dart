import '../domain/camera_repository.dart';
import '../domain/fall_incident.dart';

class MockCameraRepository implements CameraRepository {
  final List<FallIncident> _incidents = [];
  bool _mockAlert = false;

  @override
  Future<List<FallIncident>> getActiveIncidents(String? homeId) async {
    return _incidents.where((i) => i.isActive).toList();
  }

  @override
  Future<void> dismissIncident(
    String id, {
    String note = 'Người dùng bấm xác nhận an toàn (Tôi ổn)',
  }) async {
    final idx = _incidents.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(state: 'FALSE_ALARM');
    }
    _mockAlert = false;
  }

  @override
  Future<void> acknowledgeIncident(String id) async {
    final idx = _incidents.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(state: 'ACKNOWLEDGED');
    }
  }

  @override
  Future<void> resolveIncident(String id, {String note = 'Đã cấp cứu an toàn'}) async {
    final idx = _incidents.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(state: 'RESOLVED');
    }
    _mockAlert = false;
  }

  @override
  Future<AiStatus?> checkAiStatus() async {
    return AiStatus(
      isOnline: true,
      fps: 30,
      alert: _mockAlert,
      state: _mockAlert ? 'FALLEN' : 'STANDING',
      incidentType: _mockAlert ? 'ACCIDENTAL_FALL' : 'NONE',
      metrics: const FallMetrics(
        vNorm: 1.85,
        accelG: 2.7,
        spineAngle: 82.0,
        motionEnergy: 4.5,
      ),
    );
  }

  @override
  Future<bool> triggerDemoFall() async {
    _mockAlert = true;
    final demoIncident = FallIncident(
      id: 'demo-fall-${DateTime.now().millisecondsSinceEpoch}',
      roomName: 'Camera Phòng Khách',
      incidentType: 'ACCIDENTAL_FALL',
      state: 'DETECTED',
      confidenceScore: 0.98,
      countdownRemainingSec: 30,
      detectedAt: DateTime.now().toIso8601String(),
      metrics: const FallMetrics(
        vNorm: 2.1,
        accelG: 3.2,
        spineAngle: 86.5,
        motionEnergy: 5.8,
      ),
      snapshotUrl: 'http://10.0.2.2:5000/video_feed',
    );
    _incidents.add(demoIncident);
    return true;
  }

  @override
  Future<bool> dismissAiLocal() async {
    _mockAlert = false;
    return true;
  }
}
