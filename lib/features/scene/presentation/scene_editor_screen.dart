import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/error_mapper.dart' show readBackendError;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/studio.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../devices/data/device_providers.dart';
import '../../automation/domain/automation_models.dart' show RuleSchedule;
import '../../automation/domain/rule_options.dart'
    show ActionOption, ActionValueKind, deviceActions, isControllableDevice;
import '../../automation/presentation/rule_editor_parts.dart' show ScheduleSection;
import '../../devices/domain/device.dart';
import '../../home/data/home_providers.dart';
import '../../rooms/data/room_providers.dart';
import '../../rooms/domain/room.dart';
import '../data/scene_providers.dart';
import '../domain/scene.dart';
import 'scene_icons.dart';

class SceneEditorScreen extends ConsumerStatefulWidget {
  const SceneEditorScreen({this.scene, super.key});

  final Scene? scene;

  @override
  ConsumerState<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends ConsumerState<SceneEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _selectedIcon;
  late bool _enabled;
  late List<SceneAction> _actions;
  bool _isSaving = false;

  // Run times, edited locally and synced on save (same flow as the web scene editor).
  List<RuleSchedule> _schedules = [];
  List<RuleSchedule> _initialSchedules = [];
  Set<String> _savedScheduleIds = {};
  bool _loadingSchedules = false;

  final List<String> _availableIcons = [
    'home',
    'sun',
    'moon',
    'bed',
    'movie',
    'tv',
    'coffee',
    'music',
    'book',
    'work',
    'shield',
    'utensils',
    'zap',
    'party',
    'exit',
    'sparkles',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scene?.name ?? '');
    _descController = TextEditingController(
      text: widget.scene?.description ?? '',
    );
    _selectedIcon = widget.scene?.icon ?? 'home';
    _enabled = widget.scene?.enabled ?? true;
    _actions = List.of(widget.scene?.actions ?? []);
    if (widget.scene != null) _loadSchedules(widget.scene!.id);
  }

  Future<void> _loadSchedules(String sceneId) async {
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) return;
    setState(() => _loadingSchedules = true);
    try {
      final saved = await ref.read(sceneRepositoryProvider).getSchedules(homeId, sceneId);
      if (!mounted) return;
      setState(() {
        _schedules = [
          for (final s in saved)
            RuleSchedule(id: s.id, time: s.time, repeatDays: s.repeatDays, active: s.enabled),
        ];
        _initialSchedules = _schedules;
        _savedScheduleIds = {for (final s in saved) s.id};
      });
    } catch (_) {
      // The editor still works without the saved times; they just are not shown.
    } finally {
      if (mounted) setState(() => _loadingSchedules = false);
    }
  }

  Future<void> _syncSchedules(String homeId, String sceneId) async {
    final repo = ref.read(sceneRepositoryProvider);
    final kept = {for (final s in _schedules) if (s.id != null) s.id!};
    for (final id in _savedScheduleIds.difference(kept)) {
      await repo.deleteSchedule(homeId, sceneId, id);
    }
    for (final s in _schedules) {
      await repo.saveSchedule(
        homeId,
        sceneId,
        scheduleId: s.id,
        time: s.time,
        repeatDays: [...s.repeatDays]..sort(),
        enabled: s.active,
      );
    }
    ref.invalidate(sceneSchedulesProvider(sceneId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      // The name field may be scrolled off screen; bring it back and say why.
      Scrollable.ensureVisible(_formKey.currentContext!, duration: const Duration(milliseconds: 250));
      showStudioSnack(context, 'Vui lòng nhập tên kịch bản.', success: false);
      return;
    }

    if (_actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng thêm ít nhất 1 hành động thiết bị cho kịch bản.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngôi nhà trước khi lưu.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(sceneRepositoryProvider);
      final String sceneId;
      if (widget.scene == null) {
        final created = await repo.createScene(
          homeId,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          enabled: _enabled,
          actions: _actions,
        );
        sceneId = created.id;
      } else {
        sceneId = widget.scene!.id;
        await repo.updateScene(
          homeId,
          widget.scene!.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          enabled: _enabled,
          actions: _actions,
        );
      }

      await _syncSchedules(homeId, sceneId);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final reason = e is DioException
            ? readBackendError(e.response?.data).message ?? e.message ?? 'Lỗi mạng'
            : '$e';
        showStudioSnack(context, 'Lưu thất bại: $reason', success: false);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Adds a step, or edits the step at [index].
  void _showAddActionModal({int? index}) {
    // Sensors and cameras cannot run an action, same as the web picker.
    final devices = (ref.read(devicesControllerProvider).valueOrNull ?? [])
        .where(isControllableDevice)
        .toList();
    final rooms = ref.read(roomsProvider);
    final theme = studioTheme(context);

    showModalBottomSheet<SceneAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Theme(
        data: theme,
        child: _AddActionSheet(
          devices: devices,
          rooms: rooms,
          currentOrder: index ?? _actions.length,
          initial: index == null ? null : _actions[index],
        ),
      ),
    ).then((action) {
      if (action == null || !mounted) return;
      setState(() => index == null ? _actions.add(action) : _actions[index] = action);
    });
  }

  bool get _isDirty {
    final s = widget.scene;
    final initialActions = s?.actions ?? const <SceneAction>[];
    return _nameController.text.trim() != (s?.name ?? '') ||
        _descController.text.trim() != (s?.description ?? '').trim() ||
        _selectedIcon != (s?.icon ?? 'home') ||
        _enabled != (s?.enabled ?? true) ||
        _actions.length != initialActions.length ||
        [for (var i = 0; i < _actions.length; i++) !identical(_actions[i], initialActions[i])]
            .any((changed) => changed) ||
        !identical(_schedules, _initialSchedules);
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: studioTheme(context),
        child: AlertDialog(
          title: const Text('Bỏ thay đổi?'),
          content: const Text('Những thay đổi chưa lưu sẽ bị mất.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Bỏ', style: TextStyle(color: StudioColors.of(context).danger)),
            ),
          ],
        ),
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(roomsProvider); // keeps rooms (with floors) loaded for the add-action sheet
    final theme = Theme.of(context);
    final accent = StudioColors.of(context).accent;

    return PopScope(
      canPop: !_isDirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: StudioBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 68,
              flexibleSpace: GlassAppBar(
                title: widget.scene == null
                    ? 'Tạo kịch bản mới'
                    : 'Chỉnh sửa kịch bản',
                onBack: () => Navigator.of(context).maybePop(),
                // Same width as the back button so the title is centred.
                actions: const [SizedBox(width: 44)],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.navClearance * 1.5,
              ),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Preview Card
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xem trước',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: StudioColors.of(context).text,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Builder(
                              builder: (context) {
                                final atmosphere = SceneIcons.getAtmosphere(
                                  _selectedIcon,
                                );
                                return StudioCard(
                                  radius: AppRadius.card,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    children: [
                                      StudioIconTile(icon: atmosphere.icon),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _nameController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? 'Tên kịch bản'
                                                  : _nameController.text.trim(),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -0.2,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_actions.length} thiết bị · ${atmosphere.vietnameseLabel}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontSize: 11.5,
                                                    color: StudioColors.of(
                                                      context,
                                                    ).muted,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Basic Info Card
                      StudioCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin chung',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên kịch bản',
                                hintText: 'Ví dụ: Xem phim buổi tối, Đi ngủ...',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập tên kịch bản';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _descController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả (tùy chọn)',
                                hintText:
                                    'Ví dụ: Tắt đèn, hạ rèm, bật điều hoà 26°C',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Enabled Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bật kịch bản này',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: StudioColors.of(context).text,
                                  ),
                                ),
                                GlassToggle(
                                  value: _enabled,
                                  onChanged: (val) =>
                                      setState(() => _enabled = val),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Icon Selector Card
                      StudioCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biểu tượng kịch bản',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              height: 52,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _availableIcons.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: AppSpacing.sm),
                                itemBuilder: (context, i) {
                                  final iconName = _availableIcons[i];
                                  final isSelected = _selectedIcon == iconName;
                                  final atmosphere = SceneIcons.getAtmosphere(
                                    iconName,
                                  );
                                  return Tooltip(
                                    message: atmosphere.vietnameseLabel,
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(
                                          () => _selectedIcon = iconName,
                                        );
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? StudioColors.of(
                                                  context,
                                                ).accentSoft
                                              : StudioColors.of(context).soft,
                                          border: Border.all(
                                            color: isSelected
                                                ? StudioColors.of(
                                                    context,
                                                  ).accent
                                                : Colors.transparent,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Icon(
                                          atmosphere.icon,
                                          color: isSelected
                                              ? StudioColors.of(context).accent
                                              : (StudioColors.of(context).muted),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Actions List Card
                      StudioCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hành động (${_actions.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                InkWell(
                                  onTap: _showAddActionModal,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline_rounded,
                                          size: 18,
                                          color: accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Thêm hành động',
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            if (_actions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    'Chưa có hành động nào. Nhấn "Thêm hành động" để chọn thiết bị; các bước chạy từ trên xuống, kéo để đổi thứ tự.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: StudioColors.of(context).faint,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                buildDefaultDragHandles: false,
                                itemCount: _actions.length,
                                onReorder: (from, to) => setState(() {
                                  if (to > from) to--;
                                  _actions.insert(to, _actions.removeAt(from));
                                }),
                                itemBuilder: (context, index) {
                                  final act = _actions[index];
                                  final c = StudioColors.of(context);
                                  return Material(
                                    key: ObjectKey(act),
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showAddActionModal(index: index),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: c.accentSoft,
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: accent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    act.targetDeviceName,
                                                    style: theme.textTheme.bodyMedium
                                                        ?.copyWith(fontWeight: FontWeight.w600),
                                                  ),
                                                  Text(
                                                    describeAction(act.action, value: act.value),
                                                    style: theme.textTheme.bodySmall
                                                        ?.copyWith(color: c.muted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Xoá hành động',
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: c.danger,
                                              ),
                                              onPressed: () => setState(() => _actions.removeAt(index)),
                                            ),
                                            if (_actions.length > 1)
                                              ReorderableDragStartListener(
                                                index: index,
                                                child: Tooltip(
                                                  message: 'Kéo để đổi thứ tự',
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Icon(Icons.drag_indicator_rounded, color: c.faint),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Run times card (giờ : phút : giây)
                      StudioCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Lịch chạy (${_schedules.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ScheduleSection(
                              schedules: _schedules,
                              loading: _loadingSchedules,
                              emptyText: 'Chưa có lịch chạy. Kịch bản chỉ chạy khi bạn bấm "Chạy".',
                              onChanged: (next) => setState(() => _schedules = next),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Save Button
                      AppButton(
                        label: widget.scene == null
                            ? 'Tạo kịch bản'
                            : 'Lưu thay đổi',
                        isLoading: _isSaving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _AddActionSheet extends StatefulWidget {
  const _AddActionSheet({
    required this.devices,
    required this.rooms,
    required this.currentOrder,
    this.initial,
  });

  final List<Device> devices;
  final List<Room> rooms;
  final int currentOrder;

  /// Set when editing an existing step.
  final SceneAction? initial;

  @override
  State<_AddActionSheet> createState() => _AddActionSheetState();
}

class _AddActionSheetState extends State<_AddActionSheet> {
  Device? _selectedDevice;
  int? _floor; // null = tất cả tầng
  String? _roomId; // null = tất cả phòng
  String _selectedAction = 'TURN_ON';

  List<int> get _floors =>
      {for (final r in widget.rooms) if (r.floor != null) r.floor!}.toList()..sort();

  List<Room> get _visibleRooms => [
        for (final r in widget.rooms)
          if (_floor == null || r.floor == _floor) r,
      ];

  List<Device> get _visibleDevices {
    final roomIds = {for (final r in _visibleRooms) r.id};
    return [
      for (final d in widget.devices)
        if ((_roomId == null || d.roomId == _roomId) &&
            (_floor == null || roomIds.contains(d.roomId)))
          d,
    ];
  }

  void _applyFilter({int? floor, String? roomId}) {
    setState(() {
      _floor = floor;
      _roomId = roomId;
      final visible = _visibleDevices;
      if (!visible.contains(_selectedDevice)) {
        _selectedDevice = visible.isEmpty ? null : visible.first;
      }
      _syncAction();
    });
  }

  // shortcut: colour / mode / JSON steps need their own inputs; the web editor covers them.
  List<ActionOption> get _options => _selectedDevice == null
      ? const []
      : deviceActions(_selectedDevice!)
          .where((o) => o.kind == ActionValueKind.none ||
              o.kind == ActionValueKind.percentage ||
              o.kind == ActionValueKind.number)
          .toList();

  ActionOption? get _option {
    for (final o in _options) {
      if (o.code == _selectedAction) return o;
    }
    return null;
  }

  /// Keeps the chosen action valid for the chosen device.
  void _syncAction() {
    final options = _options;
    if (options.isNotEmpty && !options.any((o) => o.code == _selectedAction)) {
      _selectedAction = options.first.code;
    }
  }

  ({double min, double max, String label, String unit}) get _range => switch (_selectedAction) {
        'SET_TEMPERATURE' => (min: 16, max: 30, label: 'Nhiệt độ', unit: '°C'),
        'SET_SPEED' => (min: 0, max: 100, label: 'Tốc độ', unit: '%'),
        _ => (min: 1, max: 100, label: 'Độ sáng', unit: '%'),
      };

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final c = StudioColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: c.accent,
        labelStyle: TextStyle(color: selected ? Colors.white : c.text, fontSize: 13),
        backgroundColor: c.card,
        side: BorderSide(color: selected ? c.accent : c.border),
        showCheckmark: false,
      ),
    );
  }
  double _actionValue = 50;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      for (final d in widget.devices) {
        if (d.id == initial.targetDeviceId) _selectedDevice = d;
      }
      _selectedAction = initial.action.toUpperCase();
      final v = initial.value;
      if (v is num) _actionValue = v.toDouble();
    }
    _selectedDevice ??= widget.devices.isEmpty ? null : widget.devices.first;
    _syncAction();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: StudioColors.of(context).card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.hero),
        ),
        border: Border.all(color: StudioColors.of(context).border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: StudioColors.of(context).border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.initial == null ? 'Thêm hành động' : 'Sửa hành động',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Floor filter (only for multi-floor homes) then room filter, like the web picker.
          if (_floors.length > 1) ...[
            Text('Tầng', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Tất cả tầng', _floor == null, () => _applyFilter()),
                  for (final f in _floors)
                    _chip('Tầng $f', _floor == f, () => _applyFilter(floor: f)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (widget.rooms.isNotEmpty) ...[
            Text('Phòng', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Tất cả', _roomId == null, () => _applyFilter(floor: _floor)),
                  for (final r in _visibleRooms)
                    _chip(r.name, _roomId == r.id,
                        () => _applyFilter(floor: _floor, roomId: r.id)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Select Device Dropdown
          Text('Chọn thiết bị', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<Device>(
            key: ValueKey('$_floor/$_roomId'),
            initialValue: _selectedDevice,
            dropdownColor: StudioColors.of(context).card,
            items: _visibleDevices
                .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                .toList(),
            onChanged: (d) => setState(() {
              _selectedDevice = d;
              _syncAction();
            }),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Select Action
          Text('Hành động', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            // Rebuild when the device changes so the list matches that device.
            key: ValueKey('action/${_selectedDevice?.id}'),
            initialValue: _option?.code,
            dropdownColor: StudioColors.of(context).card,
            items: [
              for (final o in _options)
                DropdownMenuItem(value: o.code, child: Text(describeAction(o.code))),
            ],
            onChanged: (a) {
              if (a != null) setState(() => _selectedAction = a);
            },
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          if (_option != null && _option!.kind != ActionValueKind.none) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${_range.label}: ${_actionValue.clamp(_range.min, _range.max).round()}${_range.unit}',
              style: theme.textTheme.labelMedium,
            ),
            Slider(
              value: _actionValue.clamp(_range.min, _range.max),
              min: _range.min,
              max: _range.max,
              divisions: (_range.max - _range.min).round(),
              onChanged: (v) => setState(() => _actionValue = v),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: widget.initial == null ? 'Thêm' : 'Lưu',
            onPressed: _selectedDevice == null || _option == null
                ? null
                : () {
                    final action = SceneAction(
                      id: widget.initial?.id ??
                          'temp-${DateTime.now().millisecondsSinceEpoch}',
                      targetDeviceId: _selectedDevice!.id,
                      targetDeviceName: _selectedDevice!.name,
                      action: _selectedAction,
                      value: _option!.kind == ActionValueKind.none
                          ? null
                          : _actionValue.clamp(_range.min, _range.max).round(),
                      order: widget.currentOrder,
                    );
                    Navigator.of(context).pop(action);
                  },
          ),
        ],
      ),
    );
  }
}
