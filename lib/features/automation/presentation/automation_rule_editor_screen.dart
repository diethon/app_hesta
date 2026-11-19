// Trình soạn quy tắc IF/THEN — bản Flutter của RuleEditorPanel trên web.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../../core/widgets/studio.dart';
import '../../devices/data/device_providers.dart';
import '../../devices/domain/device.dart';
import '../../home/data/home_providers.dart';
import '../../rooms/data/room_providers.dart';
import '../../scene/data/scene_providers.dart';
import '../../scene/domain/scene.dart';
import '../data/automation_providers.dart';
import '../domain/automation_models.dart';
import '../domain/rule_options.dart';
import 'rule_editor_parts.dart';

class AutomationRuleEditorScreen extends ConsumerStatefulWidget {
  const AutomationRuleEditorScreen({this.rule, this.openHistory = false, super.key});

  final AutomationRule? rule;

  /// Mở thẳng tab "Lịch sử" (menu "Xem lịch sử" ở danh sách).
  final bool openHistory;

  @override
  ConsumerState<AutomationRuleEditorScreen> createState() =>
      _AutomationRuleEditorScreenState();
}

class _AutomationRuleEditorScreenState
    extends ConsumerState<AutomationRuleEditorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late bool _showDesc;
  late String _trigger;
  late bool _enabled;
  late List<RuleCondition> _conditions;
  late List<RuleAction> _actions;
  List<RuleSchedule> _schedules = [];
  late String _logicalOp;
  late bool _mixedOps;
  bool _loadingSchedules = false;
  bool _saving = false;
  late bool _showTemplates;
  late int _tab;
  int? _openCond;
  int? _openAct;
  String _snapshot = '';

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _name = TextEditingController(text: r?.name ?? '');
    _desc = TextEditingController(text: r?.description ?? '');
    _showDesc = (r?.description ?? '').isNotEmpty;
    _trigger = r?.triggerType.toUpperCase() ?? 'SENSOR';
    _enabled = r?.enabled ?? true;
    _conditions = [...?r?.conditions]..sort((a, b) => a.order.compareTo(b.order));
    _actions = [...?r?.actions]..sort((a, b) => a.order.compareTo(b.order));
    // Điều kiện đầu không nối với gì nên lấy toán tử của điều kiện thứ 2 (giống ruleToDraft).
    final ops = _conditions.skip(1).map((c) => c.logicalOperator.toUpperCase()).toSet();
    _logicalOp = ops.length == 1 ? ops.first : 'AND';
    _mixedOps = ops.length > 1;
    _showTemplates = r == null;
    _tab = widget.openHistory && r != null ? 1 : 0;
    _name.addListener(() => setState(() {}));
    _desc.addListener(() => setState(() {}));
    if (r != null && _trigger == 'SCHEDULE') _loadSchedules(r.id);
    _snapshot = _draftJson();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules(String ruleId) async {
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) return;
    setState(() => _loadingSchedules = true);
    try {
      final list = await ref.read(automationRepositoryProvider).getSchedules(homeId, ruleId);
      if (!mounted) return;
      setState(() => _schedules = list);
      _snapshot = _draftJson();
    } catch (_) {
      // Không tải được giờ chạy: để trống, người dùng vẫn thấy cảnh báo "Thêm ít nhất 1 giờ chạy".
    } finally {
      if (mounted) setState(() => _loadingSchedules = false);
    }
  }

  // ── Dữ liệu gửi đi ──

  List<RuleCondition> get _payloadConditions => _trigger == 'SCHEDULE'
      ? const []
      : [
          for (final (i, c) in _conditions.indexed)
            c.copyWith(order: i, logicalOperator: _logicalOp),
        ];

  List<RuleAction> get _payloadActions => [
    for (final (i, a) in _actions.indexed) a.copyWith(order: i),
  ];

  String _draftJson() => jsonEncode({
    'n': _name.text.trim(),
    'd': _desc.text.trim(),
    't': _trigger,
    'e': _enabled,
    'c': _payloadConditions.map((c) => c.toJson()).toList(),
    'a': _payloadActions.map((a) => a.toJson()).toList(),
    's': _trigger == 'SCHEDULE' ? _schedules.map((s) => s.toJson()).toList() : [],
  });

  bool get _dirty => !_showTemplates && _draftJson() != _snapshot;

  String? get _error => validateRuleDraft(
    name: _name.text,
    triggerType: _trigger,
    conditions: [
      for (final c in _conditions) (deviceId: c.deviceId, expectedValue: c.expectedValue),
    ],
    actions: [
      for (final a in _actions) (action: a.action, deviceId: a.deviceId, sceneId: a.sceneId),
    ],
    activeScheduleCount: _schedules.where((s) => s.active).length,
  );

  // ── Thao tác ──

  List<Device> get _devices => ref.read(devicesControllerProvider).valueOrNull ?? const [];
  List<Scene> get _scenes => ref.read(scenesListProvider).valueOrNull ?? const [];
  Map<String, String> get _roomNames => {for (final r in ref.read(roomsProvider)) r.id: r.name};

  Device? _device(String? id) => _devices.where((d) => d.id == id).firstOrNull;

  void _applyTemplate(AutomationTemplate? t) {
    final devices = _devices;
    Device? firstOf(String type) => devices.where((d) => deviceTypeCode(d).contains(type)).firstOrNull;
    setState(() {
      _showTemplates = false;
      _schedules = [];
      if (t == null) {
        _trigger = 'SENSOR';
        _conditions = [];
        _actions = [];
        _snapshot = _draftJson();
        return;
      }
      _name.text = t.name;
      _desc.text = t.description;
      _showDesc = true;
      _trigger = t.triggerType;
      switch (t.id) {
        case 'motion-light':
          final sensor = devices.where((d) => isSensorDevice(d) && attributesFor(d).any((a) => a.key == 'motion')).firstOrNull;
          _conditions = [
            RuleCondition(deviceId: sensor?.id, attribute: 'motion', operator: 'EQ', expectedValue: true),
          ];
        case 'door-ac':
          _conditions = [
            const RuleCondition(attribute: 'eventType', operator: 'EQ', expectedValue: 'EVENT'),
          ];
        default:
          _conditions = [];
          _schedules = [const RuleSchedule(time: '18:00')];
      }
      final target = t.id == 'door-ac' ? firstOf('AC') : firstOf('LIGHT');
      _actions = [
        RuleAction(deviceId: target?.id, deviceName: target?.name, action: t.action),
      ];
      _openAct = target == null ? 0 : null;
      _openCond = _trigger == 'SENSOR' && _conditions.first.deviceId == null ? 0 : null;
      // Mẫu chưa lưu cũng tính là thay đổi, để "Đóng" hỏi lại.
      _snapshot = '';
    });
  }

  void _setTrigger(String t) {
    if (_isEdit || t == _trigger) return;
    setState(() {
      _trigger = t;
      _openCond = null;
      if (t == 'EVENT') {
        _conditions = [
          const RuleCondition(attribute: 'eventType', operator: 'EQ', expectedValue: 'MOTION_DETECTED'),
        ];
      } else {
        _conditions = [];
      }
    });
  }

  Future<void> _pickConditionDevice(int i) async {
    final cond = _conditions[i];
    final d = await showDevicePicker(
      context,
      devices: _devices,
      roomNames: _roomNames,
      mode: DevicePickMode.sensorsOnly,
      title: 'Chọn cảm biến',
      selectedId: cond.deviceId,
    );
    if (d == null) return;
    final attrs = attributesFor(d);
    final keep = attrs.any((a) => a.key == cond.attribute.toLowerCase());
    final attr = keep ? null : attrs.first;
    setState(() {
      _conditions[i] = cond.copyWith(
        deviceId: d.id,
        attribute: attr?.key,
        expectedValue: attr == null
            ? null
            : attr.isBool
            ? true
            : attr.key == 'temperature'
            ? 28
            : attr.key == 'humidity'
            ? 60
            : 100,
      );
    });
  }

  Future<void> _pickActionDevice(int i) async {
    final act = _actions[i];
    final d = await showDevicePicker(
      context,
      devices: _devices,
      roomNames: _roomNames,
      mode: DevicePickMode.actionableOnly,
      title: 'Chọn thiết bị',
      selectedId: act.deviceId,
    );
    if (d == null) return;
    final options = deviceActions(d);
    final keep = options.any((o) => o.code == act.action);
    setState(() {
      _actions[i] = act.copyWith(
        deviceId: d.id,
        deviceName: d.name,
        action: keep ? null : options.first.code,
        parameters: keep ? null : defaultParamsFor(options.first.code),
      );
    });
  }

  Future<void> _pickActionScene(int i) async {
    final act = _actions[i];
    final s = await showScenePicker(context, scenes: _scenes, selectedId: act.sceneId);
    if (s == null) return;
    setState(() => _actions[i] = act.copyWith(sceneId: s.id, sceneName: s.name));
  }

  Future<void> _pickEvent() async {
    final current = _conditions.firstOrNull;
    final code = await showEventPicker(context, selected: '${current?.expectedValue ?? ''}');
    if (code == null) return;
    setState(() {
      _conditions = [
        (current ?? const RuleCondition(attribute: 'eventType', operator: 'EQ', expectedValue: ''))
            .copyWith(attribute: 'eventType', operator: 'EQ', expectedValue: code),
      ];
    });
  }

  Future<void> _pickEventSource() async {
    final current = _conditions.firstOrNull;
    if (current == null) return;
    final d = await showDevicePicker(
      context,
      devices: _devices,
      roomNames: _roomNames,
      mode: DevicePickMode.all,
      title: 'Chỉ khi từ thiết bị',
      selectedId: current.deviceId,
    );
    if (d != null) setState(() => _conditions[0] = current.copyWith(deviceId: d.id));
  }

  void _moveAction(int from, int to) => setState(() {
    final a = _actions.removeAt(from);
    _actions.insert(to, a);
    if (_openAct == from) _openAct = to;
  });

  Future<bool> _confirm(String title, String body, String ok, {bool danger = false}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: danger ? TextButton.styleFrom(foregroundColor: StudioColors.of(context).danger) : null,
            child: Text(ok),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _close() async {
    if (_dirty &&
        !await _confirm('Bỏ thay đổi?', 'Những thay đổi chưa lưu sẽ bị mất.', 'Bỏ thay đổi', danger: true)) {
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final rule = widget.rule!;
    if (!await _confirm('Xoá quy tắc?', '"${rule.name}" sẽ ngừng chạy và bị xoá vĩnh viễn.', 'Xoá', danger: true)) {
      return;
    }
    await ref.read(automationRulesListProvider.notifier).deleteRule(rule.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _duplicate() async {
    try {
      await ref.read(automationRulesListProvider.notifier).duplicateRule(widget.rule!);
      if (mounted) {
        showStudioSnack(context, 'Đã tạo bản sao (đang tắt)');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showStudioSnack(context, 'Không nhân bản được: ${_reason(e)}', success: false);
    }
  }

  String _reason(Object e) => e is DioException
      ? readBackendError(e.response?.data).message ?? e.message ?? 'Lỗi mạng'
      : e.toString();

  Future<void> _save() async {
    if (_error != null) return;
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) {
      showStudioSnack(context, 'Vui lòng chọn ngôi nhà trước khi lưu.', success: false);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(automationRepositoryProvider);
      final desc = _desc.text.trim();
      final schedules = _trigger == 'SCHEDULE' ? _schedules.map((s) => s.toJson()).toList() : null;
      if (_isEdit) {
        await repo.updateRule(
          homeId,
          widget.rule!.id,
          name: _name.text.trim(),
          description: desc.isEmpty ? null : desc,
          triggerType: _trigger,
          enabled: _enabled,
          conditions: _payloadConditions,
          actions: _payloadActions,
          schedules: schedules,
        );
      } else {
        await repo.createRule(
          homeId,
          name: _name.text.trim(),
          description: desc.isEmpty ? null : desc,
          triggerType: _trigger,
          enabled: _enabled,
          conditions: _payloadConditions,
          actions: _payloadActions,
          schedules: schedules,
        );
      }
      await ref.read(automationRulesListProvider.notifier).refresh();
      if (mounted) {
        showStudioSnack(context, _isEdit ? 'Đã lưu quy tắc' : 'Đã tạo quy tắc');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showStudioSnack(context, 'Lưu quy tắc thất bại: ${_reason(e)}', success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Giao diện ──

  @override
  Widget build(BuildContext context) {
    // Theo dõi để danh sách thiết bị/ngữ cảnh/phòng có dữ liệu khi mở bảng chọn.
    final devices = ref.watch(devicesControllerProvider).valueOrNull ?? const <Device>[];
    final scenes = ref.watch(scenesListProvider).valueOrNull ?? const <Scene>[];
    final rooms = {for (final r in ref.watch(roomsProvider)) r.id: r.name};

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: StudioBackground(
        child: Builder(
          builder: (context) {
            final c = StudioColors.of(context);
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(68),
                child: SafeArea(
                  bottom: false,
                  child: GlassAppBar(
                    title: _showTemplates ? 'Tạo quy tắc' : (_isEdit ? 'Sửa quy tắc' : 'Quy tắc mới'),
                    onBack: _close,
                    actions: [
                      if (_isEdit)
                        PopupMenuButton<VoidCallback>(
                          tooltip: 'Tuỳ chọn',
                          icon: Icon(Icons.more_horiz_rounded, color: c.text),
                          onSelected: (fn) => fn(),
                          itemBuilder: (ctx) => [
                            menuItem(ctx, Icons.copy_rounded, 'Nhân bản', _duplicate),
                            menuItem(ctx, Icons.delete_outline_rounded, 'Xoá quy tắc', _delete, danger: true),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              body: _showTemplates
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        TemplateGrid(onSelect: _applyTemplate, onBlank: () => _applyTemplate(null)),
                      ],
                    )
                  : Column(
                      children: [
                        _header(c),
                        if (_isEdit)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: SegmentedButton<int>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 0, label: Text('Thiết lập')),
                                ButtonSegment(value: 1, label: Text('Lịch sử')),
                              ],
                              selected: {_tab},
                              onSelectionChanged: (s) => setState(() => _tab = s.first),
                            ),
                          ),
                        Expanded(
                          child: _tab == 1
                              ? _History(ruleId: widget.rule!.id)
                              : _setup(c, devices, scenes, rooms),
                        ),
                      ],
                    ),
              bottomNavigationBar: _showTemplates || _tab == 1 ? null : _footer(c),
            );
          },
        ),
      ),
    );
  }

  Widget _header(StudioColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${describeTrigger(_trigger)} · ${_enabled ? 'Đang bật' : 'Đang tắt'}',
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
          ),
          GlassToggle(value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
        ],
      ),
    );
  }

  Widget _setup(
    StudioColors c,
    List<Device> devices,
    List<Scene> scenes,
    Map<String, String> rooms,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        RuleSummaryCard(
          triggerType: _trigger,
          conditions: _conditions,
          actions: _actions,
          devices: devices,
          scenes: scenes,
          schedules: _schedules,
          logicalOp: _logicalOp,
        ),
        const SizedBox(height: 20),

        _Section('1. Thông tin quy tắc'),
        TextField(
          controller: _name,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Tên quy tắc',
            hintText: 'VD: Bật đèn khi có người',
          ),
        ),
        if (_showDesc)
          TextField(
            controller: _desc,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)'),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showDesc = true),
              child: const Text('+ Thêm mô tả'),
            ),
          ),
        const SizedBox(height: 20),

        _Section('2. Khi nào (Kích hoạt)'),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'SENSOR', icon: Icon(Icons.sensors_rounded), label: Text('Cảm biến')),
            ButtonSegment(value: 'EVENT', icon: Icon(Icons.bolt_rounded), label: Text('Sự kiện')),
            ButtonSegment(value: 'SCHEDULE', icon: Icon(Icons.schedule_rounded), label: Text('Lịch giờ')),
          ],
          selected: {_trigger},
          onSelectionChanged: _isEdit ? null : (s) => _setTrigger(s.first),
        ),
        if (_isEdit)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Không thể đổi loại sau khi tạo',
              style: TextStyle(fontSize: 12, color: c.faint),
            ),
          ),
        const SizedBox(height: 12),
        ...switch (_trigger) {
          'SCHEDULE' => [
            ScheduleSection(
              schedules: _schedules,
              loading: _loadingSchedules,
              onChanged: (s) => setState(() => _schedules = s),
            ),
          ],
          'EVENT' => _eventView(c, rooms),
          _ => _sensorView(c, rooms),
        },
        const SizedBox(height: 20),

        _Section('3. Thì làm gì (Hành động ${_actions.length})'),
        if (_actions.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Cùng thiết bị chạy theo thứ tự từ trên xuống',
              style: TextStyle(fontSize: 12.5, color: c.faint),
            ),
          ),
        for (final (i, a) in _actions.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ActionStepCard(
              key: ValueKey('act$i'),
              action: a,
              index: i,
              total: _actions.length,
              device: _device(a.deviceId),
              scene: scenes.where((s) => s.id == a.sceneId).firstOrNull,
              roomName: rooms[_device(a.deviceId)?.roomId],
              expanded: _openAct == i,
              onToggle: () => setState(() => _openAct = _openAct == i ? null : i),
              onChanged: (n) => setState(() => _actions[i] = n),
              onMoveUp: () => _moveAction(i, i - 1),
              onMoveDown: () => _moveAction(i, i + 1),
              onDuplicate: () => setState(() {
                _actions.insert(i + 1, a.copyWith());
                _openAct = i + 1;
              }),
              onDelete: () => setState(() {
                _actions.removeAt(i);
                _openAct = null;
              }),
              onPickDevice: () => _pickActionDevice(i),
              onPickScene: () => _pickActionScene(i),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _AddButton(
                icon: Icons.devices_other_rounded,
                label: 'Điều khiển thiết bị',
                onTap: () => setState(() {
                  _actions.add(const RuleAction(action: 'TURN_ON'));
                  _openAct = _actions.length - 1;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AddButton(
                icon: Icons.auto_awesome_outlined,
                label: 'Chạy ngữ cảnh',
                onTap: () => setState(() {
                  _actions.add(const RuleAction(action: 'EXECUTE_SCENE'));
                  _openAct = _actions.length - 1;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _sensorView(StudioColors c, Map<String, String> rooms) {
    return [
      if (_conditions.length >= 2) ...[
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'AND', label: Text('Tất cả điều kiện (VÀ)')),
            ButtonSegment(value: 'OR', label: Text('Bất kỳ điều kiện (HOẶC)')),
          ],
          selected: {_logicalOp},
          onSelectionChanged: (s) => setState(() {
            _logicalOp = s.first;
            _mixedOps = false;
          }),
        ),
        const SizedBox(height: 10),
      ],
      if (_mixedOps)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: StudioCard(
            color: c.warn.withValues(alpha: 0.08),
            borderColor: c.warn.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quy tắc cũ này dùng lẫn VÀ / HOẶC. Khi lưu, mọi điều kiện sẽ dùng chung một toán tử.',
                  style: TextStyle(fontSize: 13, color: c.text),
                ),
                TextButton(
                  onPressed: () => setState(() => _mixedOps = false),
                  child: Text(
                    'Áp dụng toán tử kết hợp (${_logicalOp == 'OR' ? 'HOẶC' : 'VÀ'})',
                  ),
                ),
              ],
            ),
          ),
        ),
      for (final (i, cond) in _conditions.indexed) ...[
        if (i > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Center(
              child: StudioTag(label: _logicalOp == 'OR' ? 'HOẶC' : 'VÀ', color: c.accent),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ConditionCard(
            key: ValueKey('cond$i'),
            condition: cond,
            device: _device(cond.deviceId),
            roomName: rooms[_device(cond.deviceId)?.roomId],
            expanded: _openCond == i,
            onToggle: () => setState(() => _openCond = _openCond == i ? null : i),
            onChanged: (n) => setState(() => _conditions[i] = n),
            onDuplicate: () => setState(() {
              _conditions.insert(i + 1, cond.copyWith());
              _openCond = i + 1;
            }),
            onDelete: () => setState(() {
              _conditions.removeAt(i);
              _openCond = null;
            }),
            onPickDevice: () => _pickConditionDevice(i),
          ),
        ),
      ],
      const SizedBox(height: 4),
      _AddButton(
        icon: Icons.add_rounded,
        label: 'Thêm điều kiện cảm biến',
        onTap: () => setState(() {
          _conditions.add(
            RuleCondition(attribute: 'temperature', operator: 'GT', expectedValue: 30, logicalOperator: _logicalOp),
          );
          _openCond = _conditions.length - 1;
        }),
      ),
    ];
  }

  List<Widget> _eventView(StudioColors c, Map<String, String> rooms) {
    final cond = _conditions.firstOrNull;
    final code = '${cond?.expectedValue ?? ''}';
    final known = systemEvents.where((e) => e.code == code).firstOrNull;
    final src = _device(cond?.deviceId);
    return [
      const FieldLabel('Sự kiện hệ thống'),
      PickerField(
        icon: known?.icon ?? Icons.bolt_rounded,
        label: code.isEmpty ? 'Chọn sự kiện' : (known?.name ?? eventLabel(code)),
        caption: code.isEmpty ? 'Nhấn để chọn sự kiện kích hoạt' : (known?.description ?? 'Mã sự kiện: $code'),
        hasError: code.isEmpty,
        onTap: _pickEvent,
      ),
      const SizedBox(height: 14),
      FieldLabel(
        'Chỉ khi từ thiết bị (tùy chọn)',
        trailing: src == null
            ? null
            : GestureDetector(
                onTap: () => setState(() => _conditions[0] = cond!.copyWith(clearDevice: true)),
                child: Text('Xoá chọn thiết bị', style: TextStyle(fontSize: 12, color: c.danger)),
              ),
      ),
      PickerField(
        icon: deviceIconFor(src),
        label: src?.name ?? 'Mọi thiết bị',
        caption: src == null ? 'Để trống = mọi thiết bị' : rooms[src.roomId] ?? 'Thiết bị',
        online: src == null ? null : src.status == DeviceStatus.online,
        onTap: _pickEventSource,
      ),
    ];
  }

  Widget _footer(StudioColors c) {
    final err = _error;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (err != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: c.warn),
                    const SizedBox(width: 6),
                    Expanded(child: Text(err, style: TextStyle(fontSize: 12.5, color: c.warn))),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _close,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.text,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: err != null || _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isEdit ? 'Lưu quy tắc' : 'Tạo quy tắc'),
                              if (_dirty && _isEdit) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: StudioColors.of(context).text),
    ),
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.accent,
        side: BorderSide(color: c.accent.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.ruleId});

  final String ruleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = StudioColors.of(context);
    return ref.watch(automationRuleExecutionsProvider(ruleId)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text('Không tải được lịch sử', style: TextStyle(color: c.faint))),
      data: (logs) => logs.isEmpty
          ? Center(child: Text('Quy tắc này chưa chạy lần nào.', style: TextStyle(color: c.faint)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final log = logs[i];
                final ok = log.status.toUpperCase() == 'SUCCESS';
                return StudioCard(
                  padding: const EdgeInsets.all(12),
                  radius: 16,
                  child: Row(
                    children: [
                      Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, size: 20, color: ok ? c.on : c.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          log.details ?? (ok ? 'Chạy thành công' : 'Chạy không thành công'),
                          style: TextStyle(fontSize: 13.5, color: c.text),
                        ),
                      ),
                      Text(describeWhen(log.executedAt), style: TextStyle(fontSize: 12, color: c.faint)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
