import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
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

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(deviceGroupsControllerProvider.notifier).loadGroups(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                toolbarHeight: 68,
                flexibleSpace: GlassAppBar(
                  centerTitle: false,
                  title: 'Nhóm Thiết Bị',
                  onBack: () => Navigator.of(context).maybePop(),
                  actions: [
                    GlassIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Tạo nhóm mới',
                      onTap: () => _showCreateGroupSheet(context),
                    ),
                  ],
                ),
              ),
              if (groupState.isLoading && groups.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.md,
                    AppSpacing.screen,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${groups.length} nhóm đang hoạt động',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Đồng bộ nguồn và độ sáng Master Dimmer cùng lúc',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.62),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          GlassStatusPill(
                            icon: Icons.add_rounded,
                            label: 'Tạo nhóm mới',
                            color: theme.colorScheme.primary,
                            onTap: () => _showCreateGroupSheet(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (final group in groups)
                        _DeviceGroupCard(group: group),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: GlassCard(
          radius: AppRadius.card,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                  boxShadow: GlassTokens.glow(accent, intensity: 0.35),
                ),
                child: Icon(Icons.layers_outlined, size: 36, color: accent),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Chưa có nhóm thiết bị nào',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tạo nhóm để đồng bộ bật/tắt và điều khiển độ sáng Master Dimmer cùng lúc.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  onPressed: () => _showCreateGroupSheet(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Tạo nhóm đầu tiên',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
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
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final danger = isDark ? AppColors.auroraError : AppColors.error;
    final group = widget.group;
    final allDevices = ref.watch(devicesControllerProvider).valueOrNull ?? [];

    final matchedDevices = allDevices
        .where((d) => group.deviceIds.contains(d.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon, Name, Device count, Actions
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.layers_rounded, color: accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${group.deviceCount} thiết bị liên kết',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.62,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GlassIconButton(
                  icon: Icons.edit_outlined,
                  size: 38,
                  iconColor: accent,
                  tooltip: 'Chỉnh sửa nhóm',
                  onTap: () => _showEditGroupSheet(context, group),
                ),
                const SizedBox(width: AppSpacing.xs),
                GlassIconButton(
                  icon: Icons.delete_outline_rounded,
                  size: 38,
                  iconColor: danger,
                  tooltip: 'Xóa nhóm',
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),

            if (group.statusMessage != null) ...[
              const SizedBox(height: AppSpacing.sm + 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
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
                      const SizedBox(width: AppSpacing.sm),
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
                const Icon(
                  Icons.wb_sunny_rounded,
                  size: 18,
                  color: AppColors.auroraWarning,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'Master Dimmer',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.auroraWarning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${group.currentBrightness}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.auroraWarning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
                  child: _GroupPowerButton(
                    icon: Icons.power_rounded,
                    label: 'Bật tất cả',
                    color: mint,
                    onTap: () => ref
                        .read(deviceGroupsControllerProvider.notifier)
                        .toggleGroupPower(group.id, true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _GroupPowerButton(
                    icon: Icons.power_settings_new_rounded,
                    label: 'Tắt tất cả',
                    color: danger,
                    onTap: () => ref
                        .read(deviceGroupsControllerProvider.notifier)
                        .toggleGroupPower(group.id, false),
                  ),
                ),
              ],
            ),

            // Expandable Device Chips
            if (matchedDevices.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isExpanded
                            ? 'Ẩn danh sách thiết bị'
                            : 'Xem ${matchedDevices.length} thiết bị trong nhóm',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: accent,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs + 2,
                  runSpacing: AppSpacing.xs + 2,
                  children: matchedDevices.map((dev) {
                    return GlassStatusPill(
                      icon: dev.isOn
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      label: dev.name,
                      color: dev.isOn
                          ? mint
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
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

  void _showEditGroupSheet(BuildContext context, DeviceGroup group) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateGroupSheet(existingGroup: group),
    );
  }

  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final danger = isDark ? AppColors.auroraError : AppColors.error;

    showDialog<void>(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.delete_outline_rounded,
        iconColor: danger,
        title: 'Xác nhận xóa',
        content: Text(
          'Bạn có chắc chắn muốn xóa nhóm "${widget.group.name}"?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.75,
              ),
              side: BorderSide(
                color: GlassTokens.borderSolid(theme.brightness),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: danger,
              foregroundColor: isDark
                  ? AppColors.auroraCanvasTop
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(deviceGroupsControllerProvider.notifier)
                  .deleteGroup(widget.group.id);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupPowerButton extends StatelessWidget {
  const _GroupPowerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet({this.existingGroup});

  final DeviceGroup? existingGroup;

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGroup;
    if (existing != null) {
      _nameController.text = existing.name;
      _selectedIds.addAll(existing.deviceIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final mint = isDark ? AppColors.auroraMint : AppColors.auroraMintOnLight;
    final allDevices = ref.watch(devicesControllerProvider).valueOrNull ?? [];

    return GlassBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.layers_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  widget.existingGroup != null
                      ? 'Cập Nhật Nhóm Thiết Bị'
                      : 'Tạo Nhóm Thiết Bị Mới',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
            decoration: glassInputDecoration(
              context,
              labelText: 'Tên nhóm (VD: Đèn Tầng 1, Cụm Phòng Ngủ)',
              prefixIcon: const Icon(Icons.layers_rounded, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chọn thiết bị thuộc nhóm (${_selectedIds.length} đã chọn):',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: allDevices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Không có thiết bị nào khả dụng.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: allDevices.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs + 2),
                    itemBuilder: (context, idx) {
                      final dev = allDevices[idx];
                      final isSelected = _selectedIds.contains(dev.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(dev.id);
                            } else {
                              _selectedIds.add(dev.id);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: GlassTokens.durationFast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 4,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.14)
                                : GlassTokens.fill(
                                    theme.brightness,
                                    active: false,
                                  ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.5)
                                  : GlassTokens.borderSolid(theme.brightness),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                dev.isOn
                                    ? Icons.power_rounded
                                    : Icons.power_off_rounded,
                                size: 18,
                                color: dev.isOn
                                    ? mint
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                              const SizedBox(width: AppSpacing.sm + 2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dev.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      dev.subtitle ?? dev.roomId,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.55),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: isSelected
                                    ? accent
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.35,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppColors.auroraCanvasTop
                            : Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.existingGroup != null
                          ? 'Lưu Thay Đổi'
                          : 'Tạo Nhóm',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Vui lòng nhập tên nhóm'),
        ),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Vui lòng chọn ít nhất một thiết bị'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final existing = widget.existingGroup;
    final notifier = ref.read(deviceGroupsControllerProvider.notifier);
    final success = existing != null
        ? await notifier.updateGroup(
            groupId: existing.id,
            name: name,
            deviceIds: _selectedIds.toList(),
            icon: existing.icon,
          )
        : await notifier.createGroup(
            name: name,
            deviceIds: _selectedIds.toList(),
          );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraMintOnLight,
            content: Text(
              existing != null
                  ? 'Đã cập nhật nhóm thiết bị thành công'
                  : 'Đã tạo nhóm thiết bị thành công',
            ),
          ),
        );
      } else {
        final errMsg =
            ref.read(deviceGroupsControllerProvider).errorMessage ??
            'Thao tác thất bại';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.auroraError,
            content: Text(errMsg),
          ),
        );
      }
    }
  }
}
