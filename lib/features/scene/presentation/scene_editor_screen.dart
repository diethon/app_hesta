import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass/ambient_background.dart';
import '../../../core/widgets/glass/glass_app_bar.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_toggle.dart';
import '../../devices/data/device_providers.dart';
import '../../devices/domain/device.dart';
import '../../home/data/home_providers.dart';
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
    _descController = TextEditingController(text: widget.scene?.description ?? '');
    _selectedIcon = widget.scene?.icon ?? 'home';
    _enabled = widget.scene?.enabled ?? true;
    _actions = List.of(widget.scene?.actions ?? []);
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
      final repo = ref.read(sceneRepositoryProvider);
      if (widget.scene == null) {
        await repo.createScene(
          homeId,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          enabled: _enabled,
          actions: _actions,
        );
      } else {
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

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddActionModal() {
    final devices = ref.read(devicesControllerProvider).valueOrNull ?? [];

    showModalBottomSheet<SceneAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddActionSheet(
        devices: devices,
        currentOrder: _actions.length,
      ),
    ).then((newAction) {
      if (newAction != null) {
        setState(() {
          _actions.add(newAction);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

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
                title: widget.scene == null
                    ? 'Tạo ngữ cảnh mới'
                    : 'Chỉnh sửa ngữ cảnh',
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
                      // Basic Info Card
                      GlassCard(
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
                                hintText: 'Mô tả ngắn gọn mục đích của kịch bản',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Enabled Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kích hoạt kịch bản này',
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

                      // Icon Selector Card
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biểu tượng ngữ cảnh',
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
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedIcon = iconName),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? accent.withValues(alpha: 0.25)
                                            : Colors.white.withValues(alpha: 0.05),
                                        border: Border.all(
                                          color: isSelected
                                              ? accent
                                              : Colors.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Icon(
                                        SceneIcons.getIcon(iconName),
                                        color: isSelected
                                            ? accent
                                            : (isDark
                                                ? AppColors.onDarkMuted
                                                : Colors.grey.shade600),
                                        size: 24,
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
                                  'Hành động thiết bị (${_actions.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                InkWell(
                                  onTap: _showAddActionModal,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_circle_outline_rounded,
                                            size: 18, color: accent),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Thêm',
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'Chưa có hành động nào. Nhấn "+ Thêm" để chỉ định thiết bị hoạt động khi kịch bản chạy.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? AppColors.onDarkFaint
                                          : Colors.grey.shade600,
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
                                itemBuilder: (context, index) {
                                  final act = _actions[index];
                                  return Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accent.withValues(alpha: 0.15),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              act.targetDeviceName,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Lệnh: ${act.action}${act.value != null ? ' (${act.value})' : ''}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: isDark
                                                    ? AppColors.onDarkMuted
                                                    : AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded,
                                            size: 20, color: AppColors.error),
                                        onPressed: () {
                                          setState(() {
                                            _actions.removeAt(index);
                                          });
                                        },
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
                        label: widget.scene == null
                            ? 'Tạo ngữ cảnh'
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

class _AddActionSheet extends StatefulWidget {
  const _AddActionSheet({
    required this.devices,
    required this.currentOrder,
  });

  final List<Device> devices;
  final int currentOrder;

  @override
  State<_AddActionSheet> createState() => _AddActionSheetState();
}

class _AddActionSheetState extends State<_AddActionSheet> {
  Device? _selectedDevice;
  String _selectedAction = 'TURN_ON';
  double _actionValue = 50;

  final List<String> _commonActions = [
    'TURN_ON',
    'TURN_OFF',
    'TOGGLE',
    'SET_BRIGHTNESS',
    'SET_TEMPERATURE',
    'LOCK',
    'UNLOCK',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.devices.isNotEmpty) {
      _selectedDevice = widget.devices.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.auroraCanvasMid : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.hero),
        ),
        border: Border.all(color: Colors.white12),
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
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Thêm hành động vào ngữ cảnh',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Select Device Dropdown
          Text('Chọn thiết bị', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<Device>(
            initialValue: _selectedDevice,
            dropdownColor:
                isDark ? AppColors.auroraCanvasMid : AppColors.surface,
            items: widget.devices
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d.name),
                    ))
                .toList(),
            onChanged: (d) => setState(() => _selectedDevice = d),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Select Action
          Text('Hành động', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            initialValue: _selectedAction,
            dropdownColor:
                isDark ? AppColors.auroraCanvasMid : AppColors.surface,
            items: _commonActions
                .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(a),
                    ))
                .toList(),
            onChanged: (a) {
              if (a != null) setState(() => _selectedAction = a);
            },
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          // Optional value slider if brightness or temperature
          if (_selectedAction == 'SET_BRIGHTNESS') ...[
            const SizedBox(height: AppSpacing.md),
            Text('Độ sáng: ${_actionValue.round()}%',
                style: theme.textTheme.labelMedium),
            Slider(
              value: _actionValue,
              min: 1,
              max: 100,
              onChanged: (v) => setState(() => _actionValue = v),
            ),
          ] else if (_selectedAction == 'SET_TEMPERATURE') ...[
            const SizedBox(height: AppSpacing.md),
            Text('Nhiệt độ: ${_actionValue.round()}°C',
                style: theme.textTheme.labelMedium),
            Slider(
              value: _actionValue.clamp(16, 30),
              min: 16,
              max: 30,
              onChanged: (v) => setState(() => _actionValue = v),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Thêm hành động',
            onPressed: _selectedDevice == null
                ? null
                : () {
                    final action = SceneAction(
                      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                      targetDeviceId: _selectedDevice!.id,
                      targetDeviceName: _selectedDevice!.name,
                      action: _selectedAction,
                      value: (_selectedAction == 'SET_BRIGHTNESS' ||
                              _selectedAction == 'SET_TEMPERATURE')
                          ? _actionValue.round()
                          : null,
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
