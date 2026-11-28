import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/network/network_client.dart';
import '../../home/data/home_providers.dart';
import '../domain/maintenance_ticket.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepository(ref.watch(cloudApiClientProvider)),
);

final maintenanceTicketsProvider =
    FutureProvider.autoDispose<List<MaintenanceTicketSummary>>((ref) {
      final homeId = ref.watch(currentHomeIdProvider);
      if (homeId == null) return const [];
      return ref.watch(maintenanceRepositoryProvider).list(homeId);
    });

final maintenanceTicketProvider = FutureProvider.autoDispose
    .family<MaintenanceTicket, String>((ref, ticketId) {
      final homeId = ref.watch(currentHomeIdProvider);
      if (homeId == null) throw StateError('Chưa có nhà nào được chọn.');
      return ref.watch(maintenanceRepositoryProvider).get(homeId, ticketId);
    });

class MaintenanceDeviceDraft {
  const MaintenanceDeviceDraft({
    required this.deviceId,
    this.issueNote,
    this.anomalyId,
  });

  final String deviceId;
  final String? issueNote;
  final String? anomalyId;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'issueNote': ?issueNote,
    'anomalyId': ?anomalyId,
  };
}

class MaintenanceRepository {
  MaintenanceRepository(this._client);

  final NetworkClient _client;

  String _base(String homeId) => '/api/v1/homes/$homeId/maintenance-tickets';

  Future<List<MaintenanceTicketSummary>> list(String homeId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        _base(homeId),
        queryParameters: {'page': 0, 'size': 50},
      );
      final content = (response.data?['result'] as Map?)?['content'];
      if (content is! List) return const [];
      return content
          .whereType<Map>()
          .map(
            (json) => MaintenanceTicketSummary.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<MaintenanceTicket> get(String homeId, String ticketId) =>
      _ticket(() => _client.get('${_base(homeId)}/$ticketId'));

  Future<MaintenanceTicket> create(
    String homeId, {
    required String title,
    required String priority,
    required List<MaintenanceDeviceDraft> devices,
    required List<TimeSlot> slots,
    String? description,
    String? contactPhone,
  }) => _ticket(
    () => _client.post(
      _base(homeId),
      data: {
        'title': title,
        'description': ?description,
        'contactPhone': ?contactPhone,
        'priority': priority,
        'devices': [for (final d in devices) d.toJson()],
        'slots': [for (final s in slots) s.toJson()],
      },
    ),
  );

  Future<MaintenanceTicket> cancel(String homeId, String id, String? note) =>
      _action(homeId, id, 'cancel', {'note': ?note});

  Future<MaintenanceTicket> confirmSchedule(String homeId, String id) =>
      _action(homeId, id, 'schedule/confirm');

  Future<MaintenanceTicket> reschedule(
    String homeId,
    String id,
    List<TimeSlot> slots,
    String? note,
  ) => _action(homeId, id, 'schedule/reschedule', {
    'slots': [for (final s in slots) s.toJson()],
    'note': ?note,
  });

  Future<MaintenanceTicket> approveQuote(String homeId, String id) =>
      _action(homeId, id, 'quote/approve');

  Future<MaintenanceTicket> rejectQuote(
    String homeId,
    String id,
    String? note,
  ) => _action(homeId, id, 'quote/reject', {'note': ?note});

  Future<MaintenanceTicket> feedback(
    String homeId,
    String id,
    int rating,
    String? comment,
  ) => _action(homeId, id, 'feedback', {'rating': rating, 'comment': ?comment});

  Future<MaintenanceTicket> _action(
    String homeId,
    String id,
    String action, [
    Object? data,
  ]) => _ticket(() => _client.post('${_base(homeId)}/$id/$action', data: data));

  Future<MaintenanceTicket> _ticket(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      final result = (response.data as Map?)?['result'];
      return MaintenanceTicket.fromJson(
        Map<String, dynamic>.from(result as Map),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
