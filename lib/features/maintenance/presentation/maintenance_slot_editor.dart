import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/maintenance_ticket.dart';

const maxSlots = 5;

/// Khung giờ mặc định: ngày mai 09:00-11:00 (+offset ngày cho slot thêm sau).
TimeSlot defaultSlot([int dayOffset = 1]) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day + dayOffset);
  return TimeSlot(
    startAt: day.add(const Duration(hours: 9)),
    endAt: day.add(const Duration(hours: 11)),
  );
}

/// Kiểm tra sớm theo luật backend (07:00-21:00, cách hiện tại >= 2 giờ,
/// trong 14 ngày, dài 30 phút-8 giờ, không chồng nhau). Backend vẫn là nguồn quyết định.
String? slotProblem(List<TimeSlot> slots) {
  if (slots.isEmpty) return 'Thêm ít nhất 1 khung giờ rảnh.';
  final now = DateTime.now();
  final sorted = [...slots]..sort((a, b) => a.startAt.compareTo(b.startAt));
  DateTime? previousEnd;
  for (final slot in sorted) {
    final length = slot.endAt.difference(slot.startAt);
    if (length < const Duration(minutes: 30) ||
        length > const Duration(hours: 8)) {
      return 'Mỗi khung giờ dài từ 30 phút đến 8 giờ.';
    }
    if (slot.startAt.isBefore(now.add(const Duration(hours: 2)))) {
      return 'Khung giờ phải bắt đầu sau hiện tại ít nhất 2 giờ.';
    }
    if (slot.endAt.isAfter(now.add(const Duration(days: 14)))) {
      return 'Chỉ chọn khung giờ trong 14 ngày tới.';
    }
    if (slot.startAt.hour < 7 ||
        slot.endAt.day != slot.startAt.day ||
        slot.endAt.hour > 21 ||
        (slot.endAt.hour == 21 && slot.endAt.minute > 0)) {
      return 'Khung giờ phải nằm trong 07:00-21:00 của cùng một ngày.';
    }
    if (previousEnd != null && slot.startAt.isBefore(previousEnd)) {
      return 'Các khung giờ không được chồng nhau.';
    }
    previousEnd = slot.endAt;
  }
  return null;
}

class SlotListEditor extends StatelessWidget {
  const SlotListEditor({
    required this.slots,
    required this.onChanged,
    super.key,
  });

  final List<TimeSlot> slots;
  final ValueChanged<List<TimeSlot>> onChanged;

  Future<void> _edit(BuildContext context, int index) async {
    final slot = slots[index];
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: slot.startAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 14)),
    );
    if (date == null || !context.mounted) return;
    final start = await showTimePicker(
      context: context,
      helpText: 'Giờ bắt đầu',
      initialTime: TimeOfDay.fromDateTime(slot.startAt),
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      helpText: 'Giờ kết thúc',
      initialTime: TimeOfDay.fromDateTime(slot.endAt),
    );
    if (end == null) return;
    DateTime at(TimeOfDay t) =>
        DateTime(date.year, date.month, date.day, t.hour, t.minute);
    onChanged([
      for (var i = 0; i < slots.length; i++)
        i == index ? TimeSlot(startAt: at(start), endAt: at(end)) : slots[i],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('dd/MM/yyyy');
    final hour = DateFormat('HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < slots.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_rounded),
            title: Text(
              '${day.format(slots[i].startAt)}  '
              '${hour.format(slots[i].startAt)} - ${hour.format(slots[i].endAt)}',
            ),
            onTap: () => _edit(context, i),
            trailing: slots.length > 1
                ? IconButton(
                    tooltip: 'Xoá khung giờ',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => onChanged([...slots]..removeAt(i)),
                  )
                : const Icon(Icons.edit_calendar_rounded),
          ),
        if (slots.length < maxSlots)
          TextButton.icon(
            onPressed: () =>
                onChanged([...slots, defaultSlot(slots.length + 1)]),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm khung giờ'),
          ),
      ],
    );
  }
}
