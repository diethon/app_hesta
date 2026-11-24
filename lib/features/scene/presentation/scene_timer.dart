import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/studio.dart';

/// Same presets as the web (ScenePage.tsx RUN_LATER_PRESETS).
const kRunLaterPresets = <(String, int)>[
  ('10 giây', 10),
  ('1 phút', 60),
  ('5 phút', 300),
  ('15 phút', 900),
  ('30 phút', 1800),
  ('1 giờ', 3600),
];
const _units = <(String, int)>[('giây', 1), ('phút', 60), ('giờ', 3600)];
const kMaxRunLaterSeconds = 24 * 3600;

/// Server clock minus phone clock, learned from the last run-later reply so the
/// countdown matches when the server will really fire.
// shortcut: only learned after a run-later call; zero until then (fine on NTP-synced phones).
Duration sceneClockSkew = Duration.zero;

/// "1:05:09" / "4:07", same format as the web countdown.
String formatCountdown(Duration left) {
  final total = left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = (total % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Live "Chạy sau m:ss" text; shows "Sắp chạy…" while waiting for the server to fire.
class SceneCountdown extends StatefulWidget {
  const SceneCountdown({required this.runAt, this.style, super.key});

  final DateTime runAt;
  final TextStyle? style;

  @override
  State<SceneCountdown> createState() => _SceneCountdownState();
}

class _SceneCountdownState extends State<SceneCountdown> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.runAt.difference(DateTime.now().add(sceneClockSkew));
    return Text(
      left.inMilliseconds <= 0
          ? 'Sắp chạy…'
          : 'Chạy sau ${formatCountdown(left)}',
      style: widget.style,
    );
  }
}

/// Asks how long to wait; returns the delay in seconds, or null if dismissed.
Future<int?> showRunLaterSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: StudioColors.of(context).card,
    builder: (_) => const _RunLaterSheet(),
  );
}

class _RunLaterSheet extends StatefulWidget {
  const _RunLaterSheet();

  @override
  State<_RunLaterSheet> createState() => _RunLaterSheetState();
}

class _RunLaterSheetState extends State<_RunLaterSheet> {
  final _amount = TextEditingController(text: '2');
  int _unit = 60;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _seconds {
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (value == null) return null;
    final seconds = (value * _unit).round();
    return seconds >= 1 && seconds <= kMaxRunLaterSeconds ? seconds : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final seconds = _seconds;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hẹn giờ chạy một lần',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kịch bản sẽ tự chạy một lần sau khoảng thời gian bạn chọn. Đặt lại sẽ thay hẹn giờ cũ.',
            style: TextStyle(fontSize: 13, color: c.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value) in kRunLaterPresets)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(value),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.accent,
                    side: BorderSide(color: c.border),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(label),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Hoặc tự nhập', style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Số lượng',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _unit,
                items: [
                  for (final (label, value) in _units)
                    DropdownMenuItem(value: value, child: Text(label)),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: seconds == null
                    ? null
                    : () => Navigator.of(context).pop(seconds),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Hẹn giờ'),
              ),
            ],
          ),
          if (seconds == null) ...[
            const SizedBox(height: 6),
            Text(
              'Chọn từ 1 giây đến 24 giờ.',
              style: TextStyle(fontSize: 12, color: c.danger),
            ),
          ],
        ],
      ),
    );
  }
}
