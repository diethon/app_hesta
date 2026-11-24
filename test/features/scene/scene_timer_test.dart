import 'package:flutter_test/flutter_test.dart';
import 'package:syna/features/scene/presentation/scene_timer.dart';

void main() {
  test('countdown matches the web format', () {
    expect(formatCountdown(const Duration(seconds: 2)), '0:02');
    expect(formatCountdown(const Duration(minutes: 15)), '15:00');
    expect(
      formatCountdown(const Duration(hours: 1, minutes: 5, seconds: 9)),
      '1:05:09',
    );
    expect(formatCountdown(const Duration(milliseconds: 1200)), '0:02');
    expect(formatCountdown(const Duration(seconds: -3)), '0:00');
  });
}
