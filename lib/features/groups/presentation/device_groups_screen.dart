import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_slider.dart';
import '../../../core/widgets/glass/glass_status_pill.dart';
import '../../devices/data/device_providers.dart';
import '../data/device_group_providers.dart';
import '../domain/device_group.dart';

class DeviceGroupsScreen extends ConsumerStatefulWidget {
  const DeviceGroupsScreen({super.key});

  @override
  ConsumerState<DeviceGroupsScreen> createState() => _DeviceGroupsScreenState();
}

class _DeviceGroupsScreenState extends ConsumerState<DeviceGroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupState = ref.watch(deviceGroupsControllerProvider);
    final groups = groupState.groups;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nhóm Thiết Bị'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Tạo nhóm mới',
            onPressed: () => _showCreateGroupSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(deviceGroupsControllerProvider.notifier).loadGroups(),
        child: groupState.isLoading && groups.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : groups.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _DeviceGroupCard(group: group);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo nhóm mới'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.layers_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có nhóm thiết bị nào',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tạo nhóm để đồng bộ bật/tắt và điều khiển độ sáng Master Dimmer cùng lúc.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo nhóm đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateGroupSheet(),
    );
  }
}

class _DeviceGroupCard extends ConsumerStatefulWidget {
  const _DeviceGroupCard({required this.group});

  final DeviceGroup group;

  @override
  ConsumerState<_DeviceGroupCard> createState() => _DeviceGroupCardState();
}

class _DeviceGroupCardState extends ConsumerState<_DeviceGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final group = widget.group;
    final allDevices = ref.watch(devicesControllerProvider).valueOrNull ?? [];

    final matchedDevices = allDevices
        .where((d) => group.deviceIds.contains(d.id))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, Device count, Delete
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.layers_rounded, color: accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${group.deviceCount} thiết bị liên kết',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  tooltip: 'Xóa nhóm',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),

            if (group.statusMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    if (group.isExecuting) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        group.statusMessage!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Master Dimmer Section (PHO-041)
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_rounded,
                  size: 18,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Master Dimmer',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${group.currentBrightness}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            GlassSlider(
              value: (group.currentBrightness / 100).clamp(0.0, 1.0),
              label: '${group.currentBrightness}%',
              leadingIcon: Icons.brightness_low_rounded,
              trailingIcon: Icons.brightness_high_rounded,
              onChanged: (val) {
                final intVal = (val * 100).round();
                ref
                    .read(deviceGroupsControllerProvider.notifier)
                    .setGroupBrightness(group.id, intVal);
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Quick Power Controls
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(deviceGroupsControllerProvider.notifier)
                        .toggleGroupPower(group.id, true),
                    icon: const Icon(Icons.power_rounded, size: 18),
                    label: const Text('Bật tất cả'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(
                        color: AppColors.success.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(deviceGroupsControllerProvider.notifier)
                        .toggleGroupPower(group.id, false),
                    icon: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 18,
                    ),
                    label: const Text('Tắt tất cả'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Expandable Device Chips
            if (matchedDevices.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isExpanded
                          ? 'Ẩn danh sách thiết bị'
                          : 'Xem ${matchedDevices.length} thiết bị trong nhóm',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: accent,
                    ),
                  ],
                ),
              ),
              if (_isExpanded) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: matchedDevices.map((dev) {
                    return GlassStatusPill(
                      icon: dev.isOn
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      label: dev.name,
                      color: dev.isOn
                          ? accent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa nhóm "${widget.group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(deviceGroupsControllerProvider.notifier)
                  .deleteGroup(widget.group.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final allDevices = ref.watch(devicesControllerProvider).valueOrNull ?? [];

    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tạo Nhóm Thiết Bị Mới',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tên nhóm (VD: Đèn Tầng 1, Cụm Phòng Ngủ)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              prefixIcon: const Icon(Icons.layers_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chọn thiết bị thuộc nhóm:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: allDevices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('Không có thiết bị nào khả dụng.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: allDevices.length,
                    itemBuilder: (context, idx) {
                      final dev = allDevices[idx];
                      final isSelected = _selectedIds.contains(dev.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(dev.name),
                        subtitle: Text(dev.roomId),
                        secondary: Icon(
                          dev.isOn
                              ? Icons.power_rounded
                              : Icons.power_off_rounded,
                          color: dev.isOn ? accent : theme.disabledColor,
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(dev.id);
                            } else {
                              _selectedIds.remove(dev.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Tạo Nhóm'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên nhóm')));
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một thiết bị')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(deviceGroupsControllerProvider.notifier)
        .createGroup(name: name, deviceIds: _selectedIds.toList());

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo nhóm thiết bị thành công')),
        );
      }
    }
  }
}
