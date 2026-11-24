// Các mảnh của trình soạn quy tắc, bám theo bản web:
// PickerField, StepperInput, ConditionCard, ActionStepCard, DevicePickerSheet,
// EventPickerSheet, ScenePickerSheet, ScheduleSection, SummarySentence, TemplateGrid.
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/time_format.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../../core/widgets/studio.dart';
import '../../devices/domain/device.dart';
import '../../groups/domain/device_group.dart';
import '../../scene/domain/scene.dart';
import '../../scene/presentation/scene_icons.dart';
import '../domain/automation_models.dart';
import '../domain/rule_options.dart';

IconData deviceIconFor(Device? d) {
  if (d == null) return Icons.power_settings_new_rounded;
  final t = deviceTypeCode(d);
  if (t.contains('RGB')) return Icons.palette_outlined;
  if (t.contains('LIGHT') || t.contains('LED')) return Icons.lightbulb_outline_rounded;
  if (t.contains('AC') || t.contains('AIR')) return Icons.ac_unit_rounded;
  if (t.contains('FAN')) return Icons.air_rounded;
  if (t.contains('GATE') || t.contains('DOOR')) return Icons.door_sliding_outlined;
  if (t.contains('CURTAIN')) return Icons.curtains_rounded;
  if (t.contains('SOCKET') || t.contains('PLUG')) return Icons.power_outlined;
  if (t.contains('CAMERA')) return Icons.videocam_outlined;
  if (isSensorDevice(d)) return Icons.sensors_rounded;
  return Icons.devices_other_rounded;
}

/// Nhãn nhỏ phía trên mỗi ô nhập (web: chữ in hoa nhỏ).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.muted,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class PickerField extends StatelessWidget {
  const PickerField({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.hasError = false,
    this.online,
    super.key,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool hasError;

  /// null = không hiện chấm trạng thái.
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: hasError ? c.warn : c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              StudioIconTile(icon: icon, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (online != null) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: online! ? c.on : c.off,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            caption,
                            style: TextStyle(fontSize: 12, color: c.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.faint),
            ],
          ),
        ),
      ),
    );
  }
}

class StepperInput extends StatelessWidget {
  const StepperInput({
    required this.value,
    required this.onChanged,
    this.min = -1000000,
    this.max = 1000000,
    this.step = 1,
    this.unit = '',
    this.liveValue,
    super.key,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final num min;
  final num max;
  final num step;
  final String unit;
  final String? liveValue;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    Widget btn(IconData icon, num next) => IconButton.filledTonal(
      onPressed: next < min || next > max
          ? null
          : () {
              HapticFeedback.selectionClick();
              onChanged(next);
            },
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: c.soft,
        foregroundColor: c.accent,
      ),
    );
    final shown = value is double && value == value.roundToDouble()
        ? value.toInt()
        : value;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          btn(Icons.remove_rounded, value - step),
          Expanded(
            child: GestureDetector(
              onTap: () => _typeValue(context),
              child: Text(
                '$shown$unit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
            ),
          ),
          btn(Icons.add_rounded, value + step),
        ],
      ),
    );
  }

  Future<void> _typeValue(BuildContext context) async {
    final ctrl = TextEditingController(text: '$value');
    final res = await showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập giá trị'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(suffixText: unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, num.tryParse(ctrl.text.trim())),
            child: const Text('Xong'),
          ),
        ],
      ),
    );
    if (res != null) onChanged(res.clamp(min, max));
  }
}

/// Chip chọn một (chỉ số, lệnh, chế độ).
class ChoiceChipRow<T> extends StatelessWidget {
  const ChoiceChipRow({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<(T, String)> items;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (value, label) in items)
          ChoiceChip(
            label: Text(label),
            selected: value == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(value),
            selectedColor: c.accent,
            backgroundColor: c.card,
            side: BorderSide(color: value == selected ? c.accent : c.border),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: value == selected ? Colors.white : c.text,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
      ],
    );
  }
}

/// Khung thẻ mở rộng chung cho điều kiện / hành động.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.menu,
    required this.body,
    this.badge,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final List<PopupMenuEntry<VoidCallback>> menu;
  final Widget body;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return StudioCard(
      padding: EdgeInsets.zero,
      borderColor: expanded ? c.accent.withValues(alpha: 0.45) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (badge != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: c.soft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badge!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: c.faint,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12.5, color: c.muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: c.muted,
                  ),
                  PopupMenuButton<VoidCallback>(
                    tooltip: 'Tuỳ chọn',
                    icon: Icon(Icons.more_vert_rounded, color: c.muted),
                    onSelected: (fn) => fn(),
                    itemBuilder: (_) => menu,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: c.border),
            Container(
              color: c.soft.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(14),
              child: body,
            ),
          ],
        ],
      ),
    );
  }
}

PopupMenuItem<VoidCallback> menuItem(
  BuildContext context,
  IconData icon,
  String label,
  VoidCallback onTap, {
  bool danger = false,
}) {
  final c = StudioColors.of(context);
  final color = danger ? c.danger : c.text;
  return PopupMenuItem(
    value: onTap,
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    ),
  );
}

// ── Điều kiện ───────────────────────────────────────────────────────

String conditionSentence(RuleCondition cond, Device? device) {
  final dev = cond.groupId != null
      ? 'một thiết bị trong nhóm ${cond.groupName ?? '(chưa chọn)'}'
      : device?.name ?? cond.deviceName ?? 'cảm biến';
  final a = cond.attribute.toLowerCase();
  final v = cond.expectedValue;
  final yes = v == true || v == 'true' || v == 'ON';
  final no = v == false || v == 'false' || v == 'OFF';
  final neg = cond.operator.toUpperCase() == 'NE';
  if (a == 'motion' && (yes || no)) {
    return (yes != neg) ? '$dev phát hiện có người' : '$dev không còn thấy người';
  }
  if ((a == 'state' || a == 'power') && (yes || no)) {
    return '$dev ${(yes != neg) ? 'đang bật' : 'đang tắt'}';
  }
  final attr = attributeOf(device, a);
  final label = attr?.label.toLowerCase() ?? cond.attribute;
  final unit = attr?.unit ?? '';
  final shown = v == true || v == 'true'
      ? 'Có'
      : v == false || v == 'false'
      ? 'Không'
      : '${v ?? '…'}';
  final value = '$shown${unit.isEmpty || unit == 'lux' || unit == 'W' ? (unit.isEmpty ? '' : ' $unit') : unit}';
  final cmp = switch (cond.operator.toUpperCase()) {
    'GT' => 'lớn hơn',
    'GTE' => 'lớn hơn hoặc bằng',
    'LT' => 'nhỏ hơn',
    'LTE' => 'nhỏ hơn hoặc bằng',
    'NE' => 'khác',
    _ => 'bằng',
  };
  return '$label ở $dev $cmp $value';
}

/// "Hằng ngày lúc 18:00 (+1 giờ khác)" cho thẻ và trang chi tiết của quy tắc SCHEDULE.
String scheduleSentence(List<RuleSchedule> schedules) {
  final active = schedules.where((s) => s.active).toList();
  if (active.isEmpty) return 'Chưa có giờ chạy nào đang bật';
  final first = active.first;
  final more = active.length > 1 ? ' (+${active.length - 1} giờ khác)' : '';
  return '${describeDays(first.repeatDays)} lúc ${displayTime(first.time)}$more';
}

String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class ConditionCard extends StatefulWidget {
  const ConditionCard({
    required this.condition,
    required this.device,
    required this.roomName,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
    required this.onDuplicate,
    required this.onDelete,
    required this.onPickDevice,
    this.onPickGroup,
    super.key,
  });

  final RuleCondition condition;
  /// Chuyển sang theo dõi cả nhóm (đúng khi BẤT KỲ thiết bị nào thoả).
  final VoidCallback? onPickGroup;
  final Device? device;
  final String? roomName;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<RuleCondition> onChanged;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onPickDevice;

  @override
  State<ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<ConditionCard> {
  bool _customOpen = false;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final cond = widget.condition;
    final dev = widget.device;
    final offline = dev != null && dev.status == DeviceStatus.offline;
    final attr = attributeOf(dev, cond.attribute);
    final isBool = attr?.isBool == true || cond.expectedValue is bool;
    final live = liveValue(dev, cond.attribute.toLowerCase());
    final isGroup = cond.groupId != null;

    return _StepCard(
      leading: StudioIconTile(icon: isGroup ? Icons.grid_view_rounded : Icons.sensors_rounded, size: 36),
      title: isGroup
          ? (cond.groupName == null ? 'Chọn nhóm...' : 'Nhóm ${cond.groupName}')
          : dev?.name ?? cond.deviceName ?? 'Chọn thiết bị...',
      subtitle: capitalize(conditionSentence(cond, dev)),
      expanded: widget.expanded,
      onToggle: widget.onToggle,
      menu: [
        menuItem(context, Icons.copy_rounded, 'Nhân bản điều kiện', widget.onDuplicate),
        menuItem(context, Icons.delete_outline_rounded, 'Xoá điều kiện', widget.onDelete, danger: true),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onPickGroup != null) ...[
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Một thiết bị')),
                ButtonSegment(value: true, label: Text('Cả nhóm')),
              ],
              selected: {isGroup},
              onSelectionChanged: (v) {
                if (v.first) {
                  widget.onPickGroup!();
                } else {
                  widget.onChanged(cond.copyWith(clearGroup: true));
                }
              },
            ),
            const SizedBox(height: 10),
          ],
          if (isGroup) ...[
            const FieldLabel('Nhóm theo dõi'),
            PickerField(
              icon: Icons.grid_view_rounded,
              label: cond.groupName ?? 'Chọn nhóm',
              caption: 'Đúng khi bất kỳ thiết bị nào trong nhóm thoả điều kiện',
              hasError: cond.groupId!.isEmpty,
              onTap: widget.onPickGroup!,
            ),
          ] else ...[
          const FieldLabel('Thiết bị nguồn'),
          PickerField(
            icon: Icons.sensors_rounded,
            label: dev?.name ?? 'Chọn thiết bị',
            caption: dev == null
                ? 'Nhấn để chọn cảm biến kích hoạt'
                : offline
                ? 'Cảm biến đang ngoại tuyến'
                : widget.roomName ?? 'Cảm biến',
            online: dev == null ? null : !offline,
            hasError: dev == null && cond.deviceId == null,
            onTap: widget.onPickDevice,
          ),
          if (offline)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Cảm biến đang ngoại tuyến · Quy tắc vẫn có thể lưu nhưng cần thiết bị online để hoạt động.',
                style: TextStyle(fontSize: 11.5, color: c.warn),
              ),
            ),
          ],
          const SizedBox(height: 14),
          FieldLabel(
            'Chỉ số theo dõi',
            trailing: GestureDetector(
              onTap: () => setState(() => _customOpen = !_customOpen),
              child: Text(
                _customOpen ? 'Ẩn chỉ số khác' : '+ Chỉ số khác',
                style: TextStyle(fontSize: 12, color: c.accent),
              ),
            ),
          ),
          ChoiceChipRow<String>(
            items: [for (final a in attributesFor(dev)) (a.key, a.label)],
            selected: cond.attribute.toLowerCase(),
            onSelected: (key) {
              final a = attributeOf(dev, key)!;
              Object? next = cond.expectedValue;
              if (a.isBool) {
                next = true;
              } else if (next is! num) {
                next = key == 'temperature'
                    ? 28
                    : key == 'humidity'
                    ? 60
                    : 100;
              }
              // Có/không chỉ so bằng; > hay < sẽ không bao giờ khớp.
              widget.onChanged(cond.copyWith(attribute: key, expectedValue: next, operator: a.isBool ? 'EQ' : null));
            },
          ),
          if (_customOpen)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                initialValue: attr == null ? cond.attribute : '',
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Nhập tên thuộc tính tùy chỉnh (vd: co2, aqi)...',
                ),
                onChanged: (v) {
                  if (v.trim().isNotEmpty) {
                    widget.onChanged(cond.copyWith(attribute: v.trim()));
                  }
                },
              ),
            ),
          const SizedBox(height: 14),
          const FieldLabel('Điều kiện so sánh'),
          Row(
            children: [
              for (final (code, symbol, label) in operatorOptions) ...[
                if (code != operatorOptions.first.$1) const SizedBox(width: 6),
                Expanded(
                  child: _OptionTile(
                    selected: cond.operator.toUpperCase() == code,
                    onTap: () => widget.onChanged(cond.copyWith(operator: code)),
                    child: Text(
                      '$symbol  $label',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          FieldLabel(
            'Ngưỡng kích hoạt',
            trailing: live == null
                ? null
                : Text.rich(
                    TextSpan(
                      text: 'Hiện tại: ',
                      style: TextStyle(fontSize: 12, color: c.faint),
                      children: [
                        TextSpan(
                          text: live,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (isBool)
            Row(
              children: [
                for (final v in [true, false]) ...[
                  if (!v) const SizedBox(width: 6),
                  Expanded(
                    child: _OptionTile(
                      solid: true,
                      selected: cond.expectedValue == v || '${cond.expectedValue}' == '$v',
                      onTap: () => widget.onChanged(cond.copyWith(expectedValue: v)),
                      child: Text(
                        cond.attribute == 'motion'
                            ? (v ? 'Có chuyển động' : 'Không có')
                            : (v ? 'Bật (ON)' : 'Tắt (OFF)'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            StepperInput(
              value: num.tryParse('${cond.expectedValue}') ?? 0,
              unit: attr?.unit == null || attr!.unit.isEmpty
                  ? ''
                  : (attr.unit.length > 1 && attr.unit != '°C' ? ' ${attr.unit}' : attr.unit),
              onChanged: (n) => widget.onChanged(cond.copyWith(expectedValue: n)),
            ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.child,
    this.solid = false,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  /// solid = nền màu nhấn khi chọn (Có/Không); ngược lại nền nhạt + viền.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final bg = selected ? (solid ? c.accent : c.accentSoft) : c.card;
    final fg = selected ? (solid ? Colors.white : c.accent) : c.muted;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? c.accent : c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: fg,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Hành động ───────────────────────────────────────────────────────

/// Câu tóm tắt hành động như web (formatActionSummaryHuman), dùng tham số đã dịch.
String actionSentence(RuleAction act, Device? device, Scene? scene) {
  if (act.action == kDelayAction) {
    return 'Chờ ${formatDuration(num.tryParse('${act.parameters['seconds']}') ?? 0)}';
  }
  final text = _commandSentence(act, device, scene);
  final autoOff = num.tryParse('${act.parameters[kAutoOffKey] ?? ''}') ?? 0;
  final verb = autoOffVerb(act.action, act.parameters);
  return autoOff > 0 && verb != null ? '$text, ${verb.toLowerCase()} sau ${formatDuration(autoOff)}' : text;
}

String _commandSentence(RuleAction act, Device? device, Scene? scene) {
  if (act.action == 'EXECUTE_SCENE') {
    final name = scene?.name ?? act.sceneName;
    return name == null ? 'Chạy kịch bản (chưa chọn)' : 'Chạy kịch bản: $name';
  }
  final dev = act.groupId != null
      ? 'nhóm ${act.groupName ?? '(chưa chọn)'}'
      : device?.name ?? act.deviceName ?? 'Thiết bị';
  return switch (act.action) {
    'TURN_ON' => 'Bật $dev',
    'TURN_OFF' => 'Tắt $dev',
    'TOGGLE' => 'Đảo trạng thái (Bật/Tắt) $dev',
    'OPEN' => 'Mở $dev',
    'CLOSE' => 'Đóng $dev',
    'STOP' => 'Dừng $dev',
    _ => '$dev: ${describeAction(act.action, params: act.parameters)}',
  };
}

class ActionStepCard extends StatefulWidget {
  const ActionStepCard({
    required this.action,
    required this.index,
    required this.total,
    required this.device,
    required this.scene,
    required this.roomName,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDuplicate,
    required this.onDelete,
    required this.onPickDevice,
    required this.onPickScene,
    this.onPickGroup,
    this.groupDevices = const [],
    super.key,
  });

  final RuleAction action;
  final VoidCallback? onPickGroup;
  /// Thiết bị của nhóm đang chọn (bước nhóm): lệnh hiện ra là lệnh mà ít nhất một thiết bị làm được.
  final List<Device> groupDevices;
  final int index;
  final int total;
  final Device? device;
  final Scene? scene;
  final String? roomName;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<RuleAction> onChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onPickDevice;
  final VoidCallback onPickScene;

  @override
  State<ActionStepCard> createState() => _ActionStepCardState();
}

class _ActionStepCardState extends State<ActionStepCard> {
  bool _jsonOpen = false;
  String? _jsonError;

  RuleAction get _a => widget.action;

  void _setParam(String key, Object value) => widget.onChanged(
    _a.copyWith(parameters: {..._a.parameters, key: value}),
  );

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final isDelay = _a.action == kDelayAction;
    final isGroup = _a.groupId != null;
    final isScene = _a.action == 'EXECUTE_SCENE';
    final dev = widget.device;
    final scene = widget.scene;
    final offline = dev != null && dev.status == DeviceStatus.offline;
    final options = isGroup
        ? {for (final d in widget.groupDevices) for (final o in deviceActions(d)) o.code: o}.values.toList()
        : dev == null
        ? const <ActionOption>[]
        : deviceActions(dev);
    final autoOff = (num.tryParse('${_a.parameters[kAutoOffKey] ?? ''}') ?? 0).toInt();
    final undoVerb = isDelay || isScene ? null : autoOffVerb(_a.action, _a.parameters);
    final icon = isDelay
        ? Icons.hourglass_bottom_rounded
        : isGroup
        ? Icons.grid_view_rounded
        : isScene
        ? (scene == null ? Icons.auto_awesome_outlined : SceneIcons.getAtmosphere(scene.icon).icon)
        : deviceIconFor(dev);
    num p(List<String> keys, num fallback) {
      for (final k in keys) {
        final v = num.tryParse('${_a.parameters[k] ?? ''}');
        if (v != null) return v;
      }
      return fallback;
    }

    return _StepCard(
      badge: '${widget.index + 1}',
      leading: StudioIconTile(icon: icon, size: 36),
      title: isDelay
          ? 'Chờ'
          : isGroup
          ? (_a.groupName == null ? 'Chọn nhóm...' : 'Nhóm ${_a.groupName}')
          : isScene
          ? (scene?.name ?? _a.sceneName ?? 'Chọn kịch bản...')
          : (dev?.name ?? _a.deviceName ?? 'Chọn thiết bị...'),
      subtitle: actionSentence(_a, dev, scene),
      expanded: widget.expanded,
      onToggle: widget.onToggle,
      menu: [
        if (widget.index > 0)
          menuItem(context, Icons.arrow_upward_rounded, 'Di chuyển lên', widget.onMoveUp),
        if (widget.index < widget.total - 1)
          menuItem(context, Icons.arrow_downward_rounded, 'Di chuyển xuống', widget.onMoveDown),
        menuItem(context, Icons.copy_rounded, 'Nhân bản hành động', widget.onDuplicate),
        menuItem(context, Icons.delete_outline_rounded, 'Xoá hành động', widget.onDelete, danger: true),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDelay) ...[
            const FieldLabel('Chờ bao lâu rồi làm bước tiếp theo'),
            DurationField(
              label: 'Thời gian chờ',
              seconds: (num.tryParse('${_a.parameters['seconds']}') ?? 30).toInt(),
              max: kMaxDelaySeconds,
              onChanged: (s) => widget.onChanged(_a.copyWith(parameters: {'seconds': s})),
            ),
          ] else if (isGroup) ...[
            const FieldLabel('Nhóm thiết bị'),
            PickerField(
              icon: Icons.grid_view_rounded,
              label: _a.groupName ?? 'Chọn nhóm',
              caption: _a.groupId!.isEmpty
                  ? 'Nhấn để chọn nhóm'
                  : '${widget.groupDevices.length} thiết bị · thiết bị không hỗ trợ lệnh sẽ được bỏ qua',
              hasError: _a.groupId!.isEmpty,
              onTap: widget.onPickGroup ?? () {},
            ),
          ] else if (isScene) ...[
            const FieldLabel('Kịch bản thực thi'),
            PickerField(
              icon: Icons.auto_awesome_outlined,
              label: scene?.name ?? 'Chọn kịch bản',
              caption: scene == null
                  ? 'Nhấn để chọn kịch bản'
                  : '${scene.actions.length} thiết bị',
              hasError: _a.sceneId == null,
              onTap: widget.onPickScene,
            ),
          ] else ...[
            const FieldLabel('Thiết bị điều khiển'),
            PickerField(
              icon: icon,
              label: dev?.name ?? 'Chọn thiết bị',
              caption: dev == null
                  ? 'Nhấn để chọn thiết bị thực thi'
                  : offline
                  ? 'Thiết bị đang ngoại tuyến'
                  : widget.roomName ?? 'Thiết bị',
              online: dev == null ? null : !offline,
              hasError: _a.deviceId == null,
              onTap: widget.onPickDevice,
            ),
            if (offline)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Thiết bị đang ngoại tuyến · Hành động có thể không thực hiện được cho đến khi online.',
                  style: TextStyle(fontSize: 11.5, color: c.warn),
                ),
              ),
          ],

          if (!isScene && !isDelay && options.isNotEmpty) ...[
            const SizedBox(height: 14),
            const FieldLabel('Lệnh điều khiển'),
            ChoiceChipRow<String>(
              items: [for (final o in options) (o.code, o.label)],
              selected: _a.action,
              onSelected: (code) => widget.onChanged(
                _a.copyWith(action: code, parameters: defaultParamsFor(code)),
              ),
            ),
          ],

          if (undoVerb != null) ...[
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('$undoVerb sau một khoảng thời gian', style: TextStyle(fontSize: 13.5, color: c.text)),
              value: autoOff > 0,
              onChanged: (on) {
                final next = {..._a.parameters};
                if (on) {
                  next[kAutoOffKey] = 300;
                } else {
                  next.remove(kAutoOffKey);
                }
                widget.onChanged(_a.copyWith(parameters: next));
              },
            ),
            if (autoOff > 0)
              DurationField(
                label: '$undoVerb sau',
                seconds: autoOff,
                max: kMaxAutoOffSeconds,
                onChanged: (s) => _setParam(kAutoOffKey, s),
              ),
          ],

          if (!isScene && const ['OPEN', 'CLOSE', 'STOP'].contains(_a.action)) ...[
            const SizedBox(height: 14),
            const FieldLabel('Trạng thái cổng'),
            Row(
              children: [
                for (final (code, label) in const [
                  ('OPEN', 'Mở'),
                  ('STOP', 'Dừng'),
                  ('CLOSE', 'Đóng'),
                ]) ...[
                  if (code != 'OPEN') const SizedBox(width: 6),
                  Expanded(
                    child: _OptionTile(
                      solid: true,
                      selected: _a.action == code,
                      onTap: () => widget.onChanged(
                        _a.copyWith(action: code, parameters: const {}),
                      ),
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ],
            ),
          ],

          if (!isScene && _a.action == 'SET_BRIGHTNESS') ...[
            const SizedBox(height: 14),
            _Panel(
              title: 'Độ sáng',
              value: '${p(['level', 'brightness'], 50).round()}%',
              child: Slider(
                value: p(['level', 'brightness'], 50).toDouble().clamp(0, 100),
                max: 100,
                divisions: 100,
                activeColor: c.accent,
                onChanged: (v) => _setParam('level', v.round()),
              ),
            ),
          ],

          if (!isScene && (_a.action == 'SET_RGB' || _a.action == 'SET_COLOR')) ...[
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final hex = '${_a.parameters['color'] ?? _a.parameters['hex'] ?? '#ffc107'}'.toLowerCase();
                final name = colorSwatches
                    .where((s) => s.$1 == hex)
                    .map((s) => s.$2)
                    .firstOrNull;
                return _Panel(
                  title: 'Màu sắc',
                  value: name ?? 'Tuỳ chọn',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final (h, label) in colorSwatches)
                        Tooltip(
                          message: label,
                          child: GestureDetector(
                            onTap: () => widget.onChanged(
                              _a.copyWith(parameters: {..._a.parameters, ...colorParams(h)}),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: parseHex(h),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: h == hex ? c.accent : c.border,
                                  width: h == hex ? 3 : 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],

          if (!isScene && _a.action == 'SET_TEMPERATURE') ...[
            const SizedBox(height: 14),
            const FieldLabel('Nhiệt độ điều hòa'),
            StepperInput(
              value: p(['temperature', 'temp'], 26),
              min: 16,
              max: 30,
              unit: '°C',
              onChanged: (v) => _setParam('temperature', v),
            ),
          ],

          if (!isScene && _a.action == 'SET_SPEED') ...[
            const SizedBox(height: 14),
            const FieldLabel('Tốc độ'),
            StepperInput(
              value: p(['speed', 'fan'], 50),
              min: 1,
              max: 100,
              step: 5,
              unit: '%',
              onChanged: (v) => _setParam('speed', v),
            ),
          ],

          if (!isScene && _a.action == 'SET_MODE') ...[
            const SizedBox(height: 14),
            const FieldLabel('Chế độ'),
            ChoiceChipRow<String>(
              items: acModes,
              selected: '${_a.parameters['mode'] ?? 'COOL'}'.toUpperCase(),
              onSelected: (m) => _setParam('mode', m),
            ),
          ],

          if (_a.action == 'SET_STATE') ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _jsonOpen = !_jsonOpen),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cài đặt nâng cao',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.faint,
                      ),
                    ),
                  ),
                  Icon(
                    _jsonOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: c.faint,
                  ),
                ],
              ),
            ),
            if (_jsonOpen) ...[
              const SizedBox(height: 6),
              TextFormField(
                initialValue: const JsonEncoder.withIndent('  ').convert(_a.parameters),
                maxLines: 4,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(isDense: true, errorText: _jsonError),
                onChanged: (v) {
                  try {
                    final parsed = jsonDecode(v);
                    if (parsed is! Map || parsed.isEmpty) throw const FormatException();
                    setState(() => _jsonError = null);
                    widget.onChanged(
                      _a.copyWith(parameters: Map<String, dynamic>.from(parsed)),
                    );
                  } catch (_) {
                    setState(() => _jsonError = 'JSON không hợp lệ');
                  }
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.value, required this.child});

  final String title;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ── Bảng chọn (bottom sheet) ────────────────────────────────────────

enum DevicePickMode { sensorsOnly, actionableOnly, all }

Future<T?> _sheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: StudioColors.of(context).bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => FractionallySizedBox(heightFactor: 0.8, child: builder(ctx)),
  );
}

class _SheetScaffold extends StatefulWidget {
  const _SheetScaffold({
    required this.title,
    required this.hint,
    required this.builder,
  });

  final String title;
  final String hint;
  final Widget Function(String query) builder;

  @override
  State<_SheetScaffold> createState() => _SheetScaffoldState();
}

class _SheetScaffoldState extends State<_SheetScaffold> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  icon: Icon(Icons.close_rounded, color: c.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: widget.hint,
              ),
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          Expanded(child: widget.builder(_q)),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: StudioCard(
          onTap: enabled ? onTap : null,
          padding: const EdgeInsets.all(10),
          radius: 16,
          borderColor: selected ? c.accent : null,
          color: selected ? c.accentSoft : null,
          child: Row(
            children: [
              StudioIconTile(icon: icon, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: c.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: c.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? c.accent : c.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Device?> showDevicePicker(
  BuildContext context, {
  required List<Device> devices,
  required Map<String, String> roomNames,
  required DevicePickMode mode,
  required String title,
  String? selectedId,
}) {
  final sensorsMode = mode == DevicePickMode.sensorsOnly;
  return _sheet<Device>(
    context,
    (ctx) => _SheetScaffold(
      title: title,
      hint: sensorsMode
          ? 'Tìm theo tên cảm biến hoặc phòng...'
          : 'Tìm theo tên thiết bị hoặc phòng...',
      builder: (q) {
        bool match(Device d) =>
            q.isEmpty ||
            d.name.toLowerCase().contains(q) ||
            (roomNames[d.roomId] ?? '').toLowerCase().contains(q);
        final sensors = devices.where((d) => isSensorDevice(d) && match(d)).toList();
        final controls = devices.where((d) => isControllableDevice(d) && match(d)).toList();
        final selectable = switch (mode) {
          DevicePickMode.sensorsOnly => sensors,
          DevicePickMode.actionableOnly => controls,
          DevicePickMode.all => devices.where(match).toList(),
        };
        // Như web: hiện thêm nhóm "không chọn được" để người dùng hiểu vì sao thiết bị không có ở đây.
        final others = switch (mode) {
          DevicePickMode.sensorsOnly => controls,
          DevicePickMode.actionableOnly => sensors,
          DevicePickMode.all => const <Device>[],
        };
        final c = StudioColors.of(ctx);
        Widget row(Device d, {bool enabled = true}) => _PickRow(
          icon: deviceIconFor(d),
          title: d.name,
          subtitle: [
            roomNames[d.roomId] ?? 'Chưa gán phòng',
            if (d.status == DeviceStatus.offline) 'Ngoại tuyến',
            if (!enabled) sensorsMode ? 'Không phải cảm biến' : 'Chỉ đọc · không thể điều khiển',
          ].join(' · '),
          selected: d.id == selectedId,
          enabled: enabled,
          onTap: () => Navigator.pop(ctx, d),
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (selectable.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  sensorsMode ? 'Không có cảm biến phù hợp.' : 'Không có thiết bị phù hợp.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.faint),
                ),
              ),
            for (final d in selectable) row(d),
            if (others.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                child: Text(
                  sensorsMode ? 'Thiết bị khác (${others.length})' : 'Cảm biến (${others.length})',
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.muted),
                ),
              ),
              for (final d in others) row(d, enabled: false),
            ],
          ],
        );
      },
    ),
  );
}

Future<String?> showEventPicker(BuildContext context, {String? selected}) {
  return _sheet<String>(
    context,
    (ctx) => _SheetScaffold(
      title: 'Chọn sự kiện hệ thống',
      hint: 'Tìm theo tên sự kiện hoặc mô tả...',
      builder: (q) {
        final c = StudioColors.of(ctx);
        final list = systemEvents
            .where(
              (e) =>
                  q.isEmpty ||
                  e.name.toLowerCase().contains(q) ||
                  e.description.toLowerCase().contains(q) ||
                  e.code.toLowerCase().contains(q),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final e in list)
              _PickRow(
                icon: e.icon,
                title: e.name,
                subtitle: e.description,
                selected: e.code == selected,
                onTap: () => Navigator.pop(ctx, e.code),
              ),
            if (list.isEmpty && q.isNotEmpty)
              StudioCard(
                child: Column(
                  children: [
                    Text(
                      'Dùng mã sự kiện tùy chỉnh: ${q.toUpperCase()}',
                      style: TextStyle(color: c.muted),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: c.accent),
                      onPressed: () => Navigator.pop(ctx, q.toUpperCase()),
                      child: const Text('Sử dụng mã sự kiện này'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}

Future<Scene?> showScenePicker(
  BuildContext context, {
  required List<Scene> scenes,
  String? selectedId,
}) {
  return _sheet<Scene>(
    context,
    (ctx) => _SheetScaffold(
      title: 'Chọn kịch bản',
      hint: 'Tìm kịch bản...',
      builder: (q) {
        final list = scenes.where((s) => q.isEmpty || s.name.toLowerCase().contains(q)).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có kịch bản nào.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: StudioColors.of(ctx).faint),
                ),
              ),
            for (final s in list)
              _PickRow(
                icon: SceneIcons.getAtmosphere(s.icon).icon,
                title: s.name,
                subtitle: '${s.actions.length} thiết bị${s.enabled ? '' : ' · Đã tắt'}',
                selected: s.id == selectedId,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        );
      },
    ),
  );
}

// ── Giờ chạy ────────────────────────────────────────────────────────

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({
    required this.schedules,
    required this.onChanged,
    this.loading = false,
    this.emptyText = 'Chưa có giờ chạy. Thêm ít nhất 1 giờ để quy tắc tự chạy.',
    super.key,
  });

  final String emptyText;
  final List<RuleSchedule> schedules;
  final ValueChanged<List<RuleSchedule>> onChanged;
  final bool loading;

  Future<void> _edit(BuildContext context, int? index) async {
    final current = index == null
        ? const RuleSchedule(time: '07:00:00')
        : schedules[index];
    final result = await showModalBottomSheet<RuleSchedule>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: StudioColors.of(context).bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScheduleEditor(initial: current, isNew: index == null),
    );
    if (result == null) return;
    final next = [...schedules];
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (schedules.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              emptyText,
              style: TextStyle(fontSize: 13, color: c.faint),
            ),
          ),
        for (final (i, s) in schedules.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StudioCard(
              onTap: () => _edit(context, i),
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              radius: 16,
              child: Row(
                children: [
                  Icon(Icons.alarm_rounded, color: s.active ? c.accent : c.off),
                  const SizedBox(width: 10),
                  // Time above, repeat days below — same as the web schedule row.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTime(s.time),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: s.active ? c.text : c.muted,
                          ),
                        ),
                        Text(
                          describeDays(s.repeatDays),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  GlassToggle(
                    value: s.active,
                    onChanged: (v) {
                      final next = [...schedules];
                      next[i] = s.copyWith(active: v);
                      onChanged(next);
                    },
                  ),
                  IconButton(
                    tooltip: 'Sửa giờ chạy',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.edit_outlined, color: c.muted, size: 20),
                    onPressed: () => _edit(context, i),
                  ),
                  IconButton(
                    tooltip: 'Xoá giờ chạy',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline_rounded, color: c.danger),
                    onPressed: () => onChanged([...schedules]..removeAt(i)),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _edit(context, null),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm giờ chạy'),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.accent,
            side: BorderSide(color: c.border),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor({required this.initial, required this.isNew});

  final RuleSchedule initial;
  final bool isNew;

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  late String _time = widget.initial.time;
  late final List<FixedExtentScrollController> _wheels = [
    for (final v in formatHms(_time).split(':').map(int.parse)) FixedExtentScrollController(initialItem: v),
  ];

  @override
  void dispose() {
    for (final w in _wheels) {
      w.dispose();
    }
    super.dispose();
  }
  late final Set<int> _days = {...widget.initial.repeatDays};
  static const _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isNew ? 'Thêm giờ chạy' : 'Sửa giờ chạy',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text),
          ),
          const SizedBox(height: 16),
          Text(
            _time,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: c.text),
          ),
          const FieldLabel('Giờ : phút : giây'),
          SizedBox(
            height: 180,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  pickerTextStyle: TextStyle(fontSize: 20, color: c.text),
                ),
              ),
              // Same H:M:S wheel the web form offers. Own columns instead of CupertinoTimerPicker,
              // whose Vietnamese labels pad only the hours and glue "0giây" together.
              child: Row(
                children: [
                  for (final (i, unit) in const [(0, 'giờ'), (1, 'phút'), (2, 'giây')])
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _wheels[i],
                        itemExtent: 36,
                        looping: true,
                        onSelectedItemChanged: (_) => setState(() {
                          String two(FixedExtentScrollController w) =>
                              (w.selectedItem % (w == _wheels[0] ? 24 : 60)).toString().padLeft(2, '0');
                          _time = '${two(_wheels[0])}:${two(_wheels[1])}:${two(_wheels[2])}';
                        }),
                        children: [
                          for (var v = 0; v < (i == 0 ? 24 : 60); v++)
                            Center(child: Text('${v.toString().padLeft(2, '0')} $unit')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const FieldLabel('Lặp lại'),
          Row(
            children: [
              for (var d = 1; d <= 7; d++) ...[
                if (d > 1) const SizedBox(width: 4),
                Expanded(
                  child: _OptionTile(
                    solid: true,
                    selected: _days.contains(d),
                    onTap: () => setState(() {
                      if (!_days.remove(d)) _days.add(d);
                    }),
                    child: Text(_labels[d - 1], textAlign: TextAlign.center),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _days.isEmpty ? 'Không chọn ngày nào = chạy hằng ngày.' : describeDays(_days.toList()),
            style: TextStyle(fontSize: 12.5, color: c.muted),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.pop(
              context,
              widget.initial.copyWith(time: _time, repeatDays: _days.toList()..sort()),
            ),
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }
}

// ── Câu tóm tắt ─────────────────────────────────────────────────────

class RuleSummaryCard extends StatelessWidget {
  const RuleSummaryCard({
    required this.triggerType,
    required this.conditions,
    required this.actions,
    required this.devices,
    required this.scenes,
    required this.schedules,
    required this.logicalOp,
    super.key,
  });

  final String triggerType;
  final List<RuleCondition> conditions;
  final List<RuleAction> actions;
  final List<Device> devices;
  final List<Scene> scenes;
  final List<RuleSchedule> schedules;
  final String logicalOp;

  Device? _dev(String? id) => devices.where((d) => d.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final bold = TextStyle(fontWeight: FontWeight.w700, color: c.text);
    final faint = TextStyle(fontStyle: FontStyle.italic, color: c.faint);

    final trigger = <InlineSpan>[];
    if (triggerType == 'SCHEDULE') {
      final first = schedules.firstOrNull;
      final days = first == null ? 'Hằng ngày' : describeDays(first.repeatDays);
      trigger.addAll([
        TextSpan(text: days == 'Hằng ngày' ? 'Mỗi ngày lúc ' : '$days lúc '),
        TextSpan(text: first == null ? 'giờ bạn chọn' : displayTime(first.time), style: bold),
        if (schedules.length > 1) TextSpan(text: ' (+${schedules.length - 1} giờ khác)'),
      ]);
    } else if (triggerType == 'EVENT') {
      final first = conditions.firstOrNull;
      final code = '${first?.expectedValue ?? ''}';
      final src = _dev(first?.deviceId)?.name ?? first?.deviceName;
      trigger.addAll([
        const TextSpan(text: 'Khi '),
        TextSpan(text: eventFriendlyNames[code] ?? 'thiết bị báo có sự kiện', style: bold),
        if (src != null) ...[const TextSpan(text: ' từ '), TextSpan(text: src, style: bold)],
      ]);
    } else if (conditions.isEmpty) {
      trigger.add(TextSpan(text: '…chọn cảm biến…', style: faint));
    } else {
      trigger.add(const TextSpan(text: 'Khi '));
      for (final (i, cond) in conditions.indexed) {
        if (i > 0) {
          trigger.add(TextSpan(text: logicalOp == 'OR' ? ' hoặc ' : ' và ', style: TextStyle(color: c.faint)));
        }
        trigger.add(TextSpan(text: conditionSentence(cond, _dev(cond.deviceId)), style: bold));
      }
    }

    final acts = <InlineSpan>[];
    if (actions.isEmpty) {
      acts.add(TextSpan(text: '…thêm hành động…', style: faint));
    } else {
      acts.add(const TextSpan(text: 'thì '));
      for (final (i, a) in actions.indexed) {
        if (i > 0) acts.add(TextSpan(text: i == actions.length - 1 ? ', rồi ' : ', '));
        final scene = scenes.where((s) => s.id == a.sceneId).firstOrNull;
        acts.add(TextSpan(text: actionSentence(a, _dev(a.deviceId), scene).toLowerCaseFirst(), style: bold));
      }
    }

    return StudioCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudioIconTile(icon: Icons.auto_awesome_outlined, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tóm tắt quy tắc',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.faint),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 14, height: 1.45, color: c.muted),
                    children: [...trigger, const TextSpan(text: ', '), ...acts, const TextSpan(text: '.')],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String toLowerCaseFirst() => isEmpty ? this : '${this[0].toLowerCase()}${substring(1)}';
}

// ── Mẫu tạo nhanh ───────────────────────────────────────────────────

class TemplateGrid extends StatelessWidget {
  const TemplateGrid({required this.onSelect, required this.onBlank, super.key});

  final ValueChanged<AutomationTemplate> onSelect;
  final VoidCallback onBlank;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bắt đầu nhanh với mẫu',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text),
        ),
        const SizedBox(height: 4),
        Text(
          'Chọn một mẫu rồi chỉnh lại theo ý bạn, hoặc tự tạo từ đầu.',
          style: TextStyle(fontSize: 13, color: c.muted),
        ),
        const SizedBox(height: 14),
        for (final t in automationTemplates)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: StudioCard(
              onTap: () => onSelect(t),
              child: Row(
                children: [
                  StudioIconTile(icon: t.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text),
                        ),
                        const SizedBox(height: 2),
                        Text(t.description, style: TextStyle(fontSize: 12.5, color: c.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.faint),
                ],
              ),
            ),
          ),
        StudioCard(
          onTap: onBlank,
          color: c.soft,
          child: Row(
            children: [
              const StudioIconTile(icon: Icons.add_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tự tạo từ đầu',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Nhóm thiết bị & thời gian ───────────────────────────────────────

Future<DeviceGroup?> showGroupPicker(
  BuildContext context, {
  required List<DeviceGroup> groups,
  String? selectedId,
}) {
  return _sheet<DeviceGroup>(
    context,
    (ctx) => _SheetScaffold(
      title: 'Chọn nhóm thiết bị',
      hint: 'Tìm nhóm...',
      builder: (q) {
        final list = groups.where((g) => q.isEmpty || g.name.toLowerCase().contains(q)).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có nhóm nào. Tạo nhóm ở trang Thiết bị.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: StudioColors.of(ctx).faint),
                ),
              ),
            for (final g in list)
              _PickRow(
                icon: Icons.grid_view_rounded,
                title: g.name,
                subtitle: g.deviceIds.isEmpty ? 'Nhóm chưa có thiết bị' : '${g.deviceIds.length} thiết bị',
                selected: g.id == selectedId,
                onTap: g.deviceIds.isEmpty ? () {} : () => Navigator.pop(ctx, g),
              ),
          ],
        );
      },
    ),
  );
}

/// Ô số + đơn vị (giây/phút/giờ); chỉ báo về khi giá trị nằm trong 1..[max] giây.
class DurationField extends StatefulWidget {
  const DurationField({
    required this.seconds,
    required this.max,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final int seconds;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  State<DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<DurationField> {
  static const _units = <(String, int)>[('giây', 1), ('phút', 60), ('giờ', 3600)];
  late int _unit = _bestUnit(widget.seconds);
  late final _text = TextEditingController(text: '${widget.seconds ~/ _unit}');

  static int _bestUnit(int s) => s >= 3600 && s % 3600 == 0 ? 3600 : s >= 60 && s % 60 == 0 ? 60 : 1;

  int? _value(String text, int unit) {
    final v = double.tryParse(text.replaceAll(',', '.'));
    if (v == null) return null;
    final s = (v * unit).round();
    return s >= 1 && s <= widget.max ? s : null;
  }

  @override
  void didUpdateWidget(DurationField old) {
    super.didUpdateWidget(old);
    // Giá trị khác từ bên ngoài (vd nhân bản bước) thì hiện lại; lần sửa của chính ô này thì giữ nguyên chữ.
    if (widget.seconds != _value(_text.text, _unit)) {
      _unit = _bestUnit(widget.seconds);
      _text.text = '${widget.seconds ~/ _unit}';
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _commit() {
    final s = _value(_text.text, _unit);
    setState(() {});
    if (s != null && s != widget.seconds) widget.onChanged(s);
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final valid = _value(_text.text, _unit) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 96,
              child: TextField(
                controller: _text,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(isDense: true, labelText: widget.label),
                onChanged: (_) => _commit(),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _unit,
              items: [for (final (l, v) in _units) DropdownMenuItem(value: v, child: Text(l))],
              onChanged: (v) {
                _unit = v ?? _unit;
                _commit();
              },
            ),
          ],
        ),
        if (!valid)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Chọn từ 1 giây đến ${formatDuration(widget.max)}.',
              style: TextStyle(fontSize: 12, color: c.danger),
            ),
          ),
      ],
    );
  }
}
