import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass/ambient_background.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_filter_chip.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../devices/data/device_providers.dart';
import '../../devices/domain/device.dart';
import '../../home/data/home_providers.dart';
import '../../scene/data/scene_providers.dart';
import '../../scene/domain/scene.dart';
import '../data/automation_providers.dart';
import '../domain/automation_models.dart';

class AutomationRuleEditorScreen extends ConsumerStatefulWidget {
  const AutomationRuleEditorScreen({this.rule, super.key});

  final AutomationRule? rule;

  @override
  ConsumerState<AutomationRuleEditorScreen> createState() =>
      _AutomationRuleEditorScreenState();
}

class _AutomationRuleEditorScreenState
    extends ConsumerState<AutomationRuleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _triggerType;
  late bool _enabled;
  late List<RuleCondition> _conditions;
  late List<RuleAction> _actions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name ?? '');
    _descController =
        TextEditingController(text: widget.rule?.description ?? '');
    _triggerType = widget.rule?.triggerType ?? 'SENSOR';
    _enabled = widget.rule?.enabled ?? true;
    _conditions = List.of(widget.rule?.conditions ?? []);
    _actions = List.of(widget.rule?.actions ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final homeId = ref.read(currentHomeIdProvider);
    if (homeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngôi nhà trước khi lưu.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(automationRepositoryProvider);
      if (widget.rule == null) {
        await repo.createRule(
          homeId,
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          triggerType: _triggerType,
          enabled: _enabled,
          conditions: _conditions,
          actions: _actions,
        );
      } else {
        await repo.updateRule(
          homeId,
          widget.rule!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          triggerType: _triggerType,
          enabled: _enabled,
          conditions: _conditions,
          actions: _actions,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu quy tắc thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddConditionDialog() {
    final devices = ref.read(devicesControllerProvider).valueOrNull ?? [];
    Device? selectedDevice = devices.isNotEmpty ? devices.first : null;
    String attribute = 'temperature';
    String op = 'GT';
    final valController = TextEditingController(text: '30');

    showDialog<RuleCondition>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.auroraCanvasMid
              : AppColors.surface,
          title: const Text('Thêm điều kiện (IF)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thiết bị cảm biến'),
                DropdownButtonFormField<Device>(
                  initialValue: selectedDevice,
                  isExpanded: true,
                  items: devices
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (d) => setDialogState(() => selectedDevice = d),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Thuộc tính'),
                DropdownButtonFormField<String>(
                  initialValue: attribute,
                  items: const [
                    DropdownMenuItem(
                        value: 'temperature', child: Text('Nhiệt độ (°C)')),
                    DropdownMenuItem(
                        value: 'humidity', child: Text('Độ ẩm (%)')),
                    DropdownMenuItem(
                        value: 'motion', child: Text('Chuyển động')),
                    DropdownMenuItem(
                        value: 'state', child: Text('Trạng thái bật/tắt')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => attribute = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Toán tử so sánh'),
                DropdownButtonFormField<String>(
                  initialValue: op,
                  items: const [
                    DropdownMenuItem(value: 'EQ', child: Text('= (Bằng)')),
                    DropdownMenuItem(value: 'GT', child: Text('> (Lớn hơn)')),
                    DropdownMenuItem(value: 'GTE', child: Text('>= (Lớn hơn hoặc bằng)')),
                    DropdownMenuItem(value: 'LT', child: Text('< (Nhỏ hơn)')),
                    DropdownMenuItem(value: 'LTE', child: Text('<= (Nhỏ hơn hoặc bằng)')),
                    DropdownMenuItem(value: 'NE', child: Text('!= (Khác)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => op = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Giá trị ngưỡng'),
                TextField(
                  controller: valController,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 30 hoặc true',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                dynamic parsedValue = valController.text.trim();
                if (num.tryParse(valController.text.trim()) != null) {
                  parsedValue = num.parse(valController.text.trim());
                } else if (valController.text.trim().toLowerCase() == 'true') {
                  parsedValue = true;
                } else if (valController.text.trim().toLowerCase() == 'false') {
                  parsedValue = false;
                }

                final cond = RuleCondition(
                  deviceId: selectedDevice?.id,
                  deviceName: selectedDevice?.name,
                  attribute: attribute,
                  operator: op,
                  expectedValue: parsedValue,
                  order: _conditions.length,
                );
                Navigator.of(ctx).pop(cond);
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    ).then((cond) {
      if (cond != null) setState(() => _conditions.add(cond));
    });
  }

  void _showAddActionDialog() {
    final devices = ref.read(devicesControllerProvider).valueOrNull ?? [];
    final scenes = ref.read(scenesListProvider).valueOrNull ?? [];
    bool isDevice = true;
    Device? selectedDevice = devices.isNotEmpty ? devices.first : null;
    Scene? selectedScene = scenes.isNotEmpty ? scenes.first : null;
    String actionCmd = 'TURN_ON';

    showDialog<RuleAction>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.auroraCanvasMid
              : AppColors.surface,
          title: const Text('Thêm hành động (THEN)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Thiết bị'),
                      selected: isDevice,
                      onSelected: (s) => setDialogState(() => isDevice = true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: const Text('Kịch bản (Scene)'),
                      selected: !isDevice,
                      onSelected: (s) => setDialogState(() => isDevice = false),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (isDevice) ...[
                  const Text('Chọn thiết bị'),
                  DropdownButtonFormField<Device>(
                    initialValue: selectedDevice,
                    isExpanded: true,
                    items: devices
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (d) => setDialogState(() => selectedDevice = d),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Hành động'),
                  DropdownButtonFormField<String>(
                    initialValue: actionCmd,
                    items: const [
                      DropdownMenuItem(value: 'TURN_ON', child: Text('Bật')),
                      DropdownMenuItem(value: 'TURN_OFF', child: Text('Tắt')),
                      DropdownMenuItem(value: 'TOGGLE', child: Text('Đổi trạng thái')),
                      DropdownMenuItem(value: 'LOCK', child: Text('Khóa cửa')),
                      DropdownMenuItem(value: 'UNLOCK', child: Text('Mở khóa')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => actionCmd = v);
                    },
                  ),
                ] else ...[
                  const Text('Chọn kịch bản kích hoạt'),
                  DropdownButtonFormField<Scene>(
                    initialValue: selectedScene,
                    isExpanded: true,
                    items: scenes
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (s) => setDialogState(() => selectedScene = s),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final act = RuleAction(
                  deviceId: isDevice ? selectedDevice?.id : null,
                  deviceName: isDevice ? selectedDevice?.name : null,
                  sceneId: !isDevice ? selectedScene?.id : null,
                  sceneName: !isDevice ? selectedScene?.name : null,
                  action: isDevice ? actionCmd : 'TRIGGER_SCENE',
                  order: _actions.length,
                );
                Navigator.of(ctx).pop(act);
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    ).then((act) {
      if (act != null) setState(() => _actions.add(act));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
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
                title: widget.rule == null
                    ? 'Tạo quy tắc tự động'
                    : 'Sửa quy tắc tự động',
                onBack: () => Navigator.of(context).maybePop(),
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
                      // Info Card
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin quy tắc',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên quy tắc',
                                hintText: 'Ví dụ: Bật điều hòa khi phòng quá nóng...',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập tên quy tắc';
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
                                hintText: 'Mô tả tóm tắt hành vi tự động',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kích hoạt quy tắc này',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.onDark
                                        : AppColors.onSurface,
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

                      // Trigger Type Card
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loại Trigger (Nguồn kích hoạt)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                GlassFilterChip(
                                  label: 'Cảm biến (Sensor)',
                                  selected: _triggerType == 'SENSOR',
                                  onTap: () =>
                                      setState(() => _triggerType = 'SENSOR'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                GlassFilterChip(
                                  label: 'Lịch (Schedule)',
                                  selected: _triggerType == 'SCHEDULE',
                                  onTap: () =>
                                      setState(() => _triggerType = 'SCHEDULE'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                GlassFilterChip(
                                  label: 'Sự kiện (Event)',
                                  selected: _triggerType == 'EVENT',
                                  onTap: () =>
                                      setState(() => _triggerType = 'EVENT'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // IF Conditions Card
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ĐIỀU KIỆN (IF) (${_conditions.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                InkWell(
                                  onTap: _showAddConditionDialog,
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded,
                                          size: 18,
                                          color: theme.colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Thêm',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_conditions.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'Chưa có điều kiện nào. Nhấn "+ Thêm" để tạo điều kiện kiểm tra.',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.onDarkFaint
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _conditions.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16, color: Colors.white10),
                                itemBuilder: (context, i) {
                                  final cond = _conditions[i];
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${cond.deviceName ?? cond.attribute} ${cond.operatorSymbol} ${cond.expectedValue}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: AppColors.error),
                                        onPressed: () => setState(
                                            () => _conditions.removeAt(i)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // THEN Actions Card
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'HÀNH ĐỘNG (THEN) (${_actions.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                InkWell(
                                  onTap: _showAddActionDialog,
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded,
                                          size: 18,
                                          color: theme.colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Thêm',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_actions.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'Chưa có hành động nào. Nhấn "+ Thêm" để chọn hành động thực hiện.',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.onDarkFaint
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _actions.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16, color: Colors.white10),
                                itemBuilder: (context, i) {
                                  final act = _actions[i];
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${act.deviceName ?? act.sceneName ?? "Hành động"}: ${act.action}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: AppColors.error),
                                        onPressed: () => setState(
                                            () => _actions.removeAt(i)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Save Button
                      AppButton(
                        label: widget.rule == null
                            ? 'Tạo quy tắc'
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
    );
  }
}
