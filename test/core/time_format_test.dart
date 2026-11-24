import 'package:flutter_test/flutter_test.dart';
import 'package:syna/core/utils/time_format.dart';

void main() {
  test('displayTime hides zero seconds only', () {
    expect(displayTime('22:03:00'), '22:03');
    expect(displayTime('22:03:15'), '22:03:15');
    expect(displayTime('7:5'), '07:05');
  });

  test('formatNextRun uses today / tomorrow / weekday', () {
    final now = DateTime(2026, 11, 24, 12); // Tuesday
    expect(
      formatNextRun(DateTime(2026, 11, 24, 22, 3), now: now),
      'hôm nay 22:03',
    );
    expect(
      formatNextRun(DateTime(2026, 11, 25, 7), now: now),
      'ngày mai 07:00',
    );
    expect(
      formatNextRun(DateTime(2026, 11, 26, 22, 3), now: now),
      'T5 26/11 22:03',
    );
  });
}
