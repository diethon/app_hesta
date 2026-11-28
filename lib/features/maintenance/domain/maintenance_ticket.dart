import '../../security/domain/security_models.dart' show parseDate;

/// Mirrors backend `MaintenanceTicketSummaryResponse`.
class MaintenanceTicketSummary {
  const MaintenanceTicketSummary({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.priority,
    required this.deviceNames,
    required this.createdAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.scheduleConfirmed = false,
    this.quoteTotal,
  });

  factory MaintenanceTicketSummary.fromJson(Map<String, dynamic> json) =>
      MaintenanceTicketSummary(
        id: json['id'].toString(),
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        status: json['status']?.toString() ?? 'SUBMITTED',
        priority: json['priority']?.toString() ?? 'NORMAL',
        deviceNames: [
          for (final name in (json['deviceNames'] as List? ?? const []))
            name.toString(),
        ],
        createdAt: parseDate(json['createdAt']),
        scheduledStart: _date(json['scheduledStart']),
        scheduledEnd: _date(json['scheduledEnd']),
        scheduleConfirmed: json['scheduleConfirmed'] == true,
        quoteTotal: (json['quoteTotal'] as num?)?.toDouble(),
      );

  final String id;
  final String code;
  final String title;
  final String status;
  final String priority;
  final List<String> deviceNames;
  final DateTime createdAt;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final bool scheduleConfirmed;
  final double? quoteTotal;
}

/// Mirrors backend `MaintenanceTicketResponse` (fields the app shows).
class MaintenanceTicket {
  const MaintenanceTicket({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.priority,
    required this.devices,
    required this.slots,
    required this.events,
    required this.canManage,
    required this.createdAt,
    this.description,
    this.contactPhone,
    this.createdByName,
    this.scheduledStart,
    this.scheduledEnd,
    this.scheduleConfirmed = false,
    this.adminNote,
    this.cancelReason,
    this.quote,
    this.completedAt,
    this.rating,
    this.feedback,
  });

  factory MaintenanceTicket.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(Object? value) => [
      for (final item in (value as List? ?? const []))
        if (item is Map) Map<String, dynamic>.from(item),
    ];
    final quote = json['quote'];
    return MaintenanceTicket(
      id: json['id'].toString(),
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SUBMITTED',
      priority: json['priority']?.toString() ?? 'NORMAL',
      devices: maps(
        json['devices'],
      ).map(MaintenanceDeviceLine.fromJson).toList(),
      slots: maps(json['slots']).map(TimeSlot.fromJson).toList(),
      events: maps(json['events']).map(MaintenanceEvent.fromJson).toList(),
      canManage: json['canManage'] == true,
      createdAt: parseDate(json['createdAt']),
      description: json['description'] as String?,
      contactPhone: json['contactPhone'] as String?,
      createdByName: (json['createdBy'] as Map?)?['fullName'] as String?,
      scheduledStart: _date(json['scheduledStart']),
      scheduledEnd: _date(json['scheduledEnd']),
      scheduleConfirmed: json['scheduleConfirmed'] == true,
      adminNote: json['adminNote'] as String?,
      cancelReason: json['cancelReason'] as String?,
      quote: quote is Map
          ? MaintenanceQuote.fromJson(Map<String, dynamic>.from(quote))
          : null,
      completedAt: _date(json['completedAt']),
      rating: (json['rating'] as num?)?.toInt(),
      feedback: json['feedback'] as String?,
    );
  }

  final String id;
  final String code;
  final String title;
  final String status;
  final String priority;
  final List<MaintenanceDeviceLine> devices;
  final List<TimeSlot> slots;
  final List<MaintenanceEvent> events;
  final bool canManage;
  final DateTime createdAt;
  final String? description;
  final String? contactPhone;
  final String? createdByName;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final bool scheduleConfirmed;
  final String? adminNote;
  final String? cancelReason;
  final MaintenanceQuote? quote;
  final DateTime? completedAt;
  final int? rating;
  final String? feedback;

  // Mirrors the status guards in MaintenanceTicketServiceImpl.
  bool get canCancel =>
      canManage &&
      const {'SUBMITTED', 'SCHEDULED', 'RESCHEDULE_REQUESTED'}.contains(status);
  bool get canConfirmSchedule =>
      canManage && status == 'SCHEDULED' && !scheduleConfirmed;
  bool get canReschedule => canManage && status == 'SCHEDULED';
  bool get canDecideQuote => canManage && status == 'QUOTED';
  bool get canRate =>
      canManage &&
      rating == null &&
      (status == 'COMPLETED' || status == 'CLOSED');
}

class MaintenanceDeviceLine {
  const MaintenanceDeviceLine({
    required this.deviceName,
    this.roomName,
    this.issueNote,
    this.outcome,
    this.outcomeNote,
  });

  factory MaintenanceDeviceLine.fromJson(Map<String, dynamic> json) =>
      MaintenanceDeviceLine(
        deviceName: json['deviceName']?.toString() ?? '',
        roomName: json['roomName'] as String?,
        issueNote: json['issueNote'] as String?,
        outcome: json['outcome']?.toString(),
        outcomeNote: json['outcomeNote'] as String?,
      );

  final String deviceName;
  final String? roomName;
  final String? issueNote;
  final String? outcome;
  final String? outcomeNote;
}

class TimeSlot {
  const TimeSlot({required this.startAt, required this.endAt});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    startAt: parseDate(json['startAt']),
    endAt: parseDate(json['endAt']),
  );

  final DateTime startAt;
  final DateTime endAt;

  Map<String, dynamic> toJson() => {
    'startAt': startAt.toUtc().toIso8601String(),
    'endAt': endAt.toUtc().toIso8601String(),
  };
}

class MaintenanceQuote {
  const MaintenanceQuote({
    required this.items,
    this.findings,
    this.total,
    this.currency,
    this.warrantyMonths,
    this.decision,
  });

  factory MaintenanceQuote.fromJson(Map<String, dynamic> json) =>
      MaintenanceQuote(
        items: [
          for (final item in (json['items'] as List? ?? const []))
            if (item is Map)
              MaintenanceQuoteItem.fromJson(Map<String, dynamic>.from(item)),
        ],
        findings: json['findings'] as String?,
        total: (json['total'] as num?)?.toDouble(),
        currency: json['currency'] as String?,
        warrantyMonths: (json['warrantyMonths'] as num?)?.toInt(),
        decision: json['decision']?.toString(),
      );

  final List<MaintenanceQuoteItem> items;
  final String? findings;
  final double? total;
  final String? currency;
  final int? warrantyMonths;
  final String? decision;
}

class MaintenanceQuoteItem {
  const MaintenanceQuoteItem({
    required this.description,
    required this.quantity,
    this.amount,
  });

  factory MaintenanceQuoteItem.fromJson(Map<String, dynamic> json) =>
      MaintenanceQuoteItem(
        description: json['description']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        amount: (json['amount'] as num?)?.toDouble(),
      );

  final String description;
  final int quantity;
  final double? amount;
}

class MaintenanceEvent {
  const MaintenanceEvent({
    required this.createdAt,
    this.actorName,
    this.toStatus,
    this.note,
  });

  factory MaintenanceEvent.fromJson(Map<String, dynamic> json) =>
      MaintenanceEvent(
        createdAt: parseDate(json['createdAt']),
        actorName: json['actorName'] as String?,
        toStatus: json['toStatus']?.toString(),
        note: json['note'] as String?,
      );

  final DateTime createdAt;
  final String? actorName;
  final String? toStatus;
  final String? note;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

const maintenanceStatusLabels = <String, String>{
  'SUBMITTED': 'Đã gửi',
  'SCHEDULED': 'Đã lên lịch',
  'RESCHEDULE_REQUESTED': 'Chờ đổi lịch',
  'INSPECTING': 'Đang kiểm tra',
  'QUOTED': 'Chờ duyệt báo giá',
  'REPAIRING': 'Đang sửa',
  'COMPLETED': 'Hoàn tất',
  'CLOSED': 'Đã đóng',
  'CANCELLED': 'Đã huỷ',
  'REJECTED': 'Bị từ chối',
};

const maintenancePriorityLabels = <String, String>{
  'LOW': 'Thấp',
  'NORMAL': 'Bình thường',
  'HIGH': 'Cao',
  'URGENT': 'Khẩn cấp',
};

const maintenanceOutcomeLabels = <String, String>{
  'FIXED': 'Đã sửa',
  'REPLACED': 'Đã thay',
  'NOT_REPAIRABLE': 'Không sửa được',
  'NO_ISSUE_FOUND': 'Không phát hiện lỗi',
};
