import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/maintenance/domain/maintenance_ticket.dart';
import 'package:syna/features/maintenance/presentation/maintenance_slot_editor.dart';

TimeSlot _slot(DateTime day, int startHour, int endHour) => TimeSlot(
  startAt: day.add(Duration(hours: startHour)),
  endAt: day.add(Duration(hours: endHour)),
);

void main() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  test('default slot is valid', () {
    expect(slotProblem([defaultSlot()]), isNull);
  });

  test('rejects empty, out-of-hours, too long and overlapping slots', () {
    expect(slotProblem(const []), isNotNull);
    expect(slotProblem([_slot(tomorrow, 6, 8)]), isNotNull);
    expect(slotProblem([_slot(tomorrow, 20, 22)]), isNotNull);
    expect(slotProblem([_slot(tomorrow, 8, 17)]), isNotNull);
    expect(
      slotProblem([_slot(tomorrow, 9, 11), _slot(tomorrow, 10, 12)]),
      isNotNull,
    );
    expect(
      slotProblem([_slot(tomorrow, 9, 11), _slot(tomorrow, 11, 13)]),
      isNull,
    );
  });

  test('rejects slots beyond 14 days', () {
    expect(
      slotProblem([_slot(tomorrow.add(const Duration(days: 15)), 9, 11)]),
      isNotNull,
    );
  });

  test('parses ticket detail json and action guards', () {
    final ticket = MaintenanceTicket.fromJson({
      'id': 't1',
      'code': 'MT-1',
      'title': 'Kiểm tra',
      'status': 'QUOTED',
      'priority': 'HIGH',
      'canManage': true,
      'createdAt': '2026-11-23T10:00:00Z',
      'devices': [
        {'deviceName': 'Đèn', 'roomName': 'Khách'},
      ],
      'slots': [
        {'startAt': '2026-11-24T02:00:00Z', 'endAt': '2026-11-24T04:00:00Z'},
      ],
      'quote': {
        'total': 150000,
        'items': [
          {'description': 'Công', 'quantity': 1, 'amount': 150000},
        ],
      },
      'events': [],
    });
    expect(ticket.devices.single.deviceName, 'Đèn');
    expect(ticket.quote!.total, 150000);
    expect(ticket.canDecideQuote, isTrue);
    expect(ticket.canCancel, isFalse);
  });
}
