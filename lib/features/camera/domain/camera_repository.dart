import 'fall_incident.dart';

abstract class CameraRepository {
  Future<List<FallIncident>> getActiveIncidents(String? homeId);

  Future<void> dismissIncident(String id, {String note = 'Người dùng bấm xác nhận an toàn (Tôi ổn)'});

  Future<void> acknowledgeIncident(String id);

  Future<void> resolveIncident(String id, {String note = 'Đã cấp cứu an toàn'});

  Future<AiStatus?> checkAiStatus();

  Future<bool> triggerDemoFall();

  Future<bool> dismissAiLocal();
}
