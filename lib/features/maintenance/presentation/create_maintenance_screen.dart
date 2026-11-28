import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../devices/data/device_providers.dart';
import '../../home/data/home_providers.dart';
import '../../security/data/security_repository.dart';
import '../data/maintenance_repository.dart';
import '../domain/maintenance_ticket.dart';
import 'maintenance_slot_editor.dart';

const _maxDevices = 10;

/// Form báo hỏng thiết bị. Có thể mở sẵn thiết bị/anomaly qua query
/// `?deviceId=…&anomalyId=…&note=…` (từ Trung tâm an ninh).
class CreateMaintenanceScreen extends ConsumerStatefulWidget {
  const CreateMaintenanceScreen({
    super.key,
    this.initialDeviceId,
    this.initialAnomalyId,
    this.initialNote,
  });

  final String? initialDeviceId;
  final String? initialAnomalyId;
  final String? initialNote;

  @override
  ConsumerState<CreateMaintenanceScreen> createState() =>
      _CreateMaintenanceScreenState();
}

class _CreateMaintenanceScreenState
    extends ConsumerState<CreateMaintenanceScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final Map<String, TextEditingController> _selected = {};
  String _priority = 'NORMAL';
  List<TimeSlot> _slots = [defaultSlot()];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final deviceId = widget.initialDeviceId;
    if (deviceId != null) {
      _selected[deviceId] = TextEditingController(text: widget.initialNote);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _phone.dispose();
    for (final controller in _selected.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggle(String deviceId) {
    setState(() {
      final removed = _selected.remove(deviceId);
      if (removed != null) {
        removed.dispose();
      } else if (_selected.length >= _maxDevices) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mỗi yêu cầu tối đa $_maxDevices thiết bị.'),
          ),
        );
      } else {
        _selected[deviceId] = TextEditingController();
      }
    });
  }

  String? _trimmed(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit(String homeId, String title) async {
    final messenger = ScaffoldMessenger.of(context);
    final problem = _selected.isEmpty
        ? 'Chọn ít nhất 1 thiết bị cần kiểm tra.'
        : title.isEmpty
        ? 'Nhập tiêu đề yêu cầu.'
        : slotProblem(_slots);
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final ticket = await ref
          .read(maintenanceRepositoryProvider)
          .create(
            homeId,
            title: title,
            priority: _priority,
            description: _trimmed(_description),
            contactPhone: _trimmed(_phone),
            slots: _slots,
            devices: [
              for (final entry in _selected.entries)
                MaintenanceDeviceDraft(
                  deviceId: entry.key,
                  issueNote: _trimmed(entry.value),
                  anomalyId: entry.key == widget.initialDeviceId
                      ? widget.initialAnomalyId
                      : null,
                ),
            ],
          );
      ref.invalidate(maintenanceTicketsProvider);
      ref.invalidate(anomaliesProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Đã gửi yêu cầu ${ticket.code}')),
      );
      if (mounted) context.pushReplacement('/maintenance/${ticket.id}');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeId = ref.watch(currentHomeIdProvider);
    final devices = ref.watch(devicesControllerProvider);
    final deviceList = devices.valueOrNull ?? const [];
    final firstName = deviceList
        .where((d) => _selected.containsKey(d.id))
        .map((d) => d.name)
        .firstOrNull;
    // Tự gợi ý tiêu đề từ thiết bị đầu tiên để case 1 thiết bị không cần gõ.
    final autoTitle = firstName == null
        ? ''
        : 'Kiểm tra $firstName${_selected.length > 1 ? ' và ${_selected.length - 1} thiết bị khác' : ''}';

    Widget section(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GlassContainer(
        radius: AppRadius.card,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GlassAppBar(title: 'Báo hỏng thiết bị', onBack: () => context.pop()),
          Expanded(
            child: homeId == null
                ? const Center(child: Text('Bạn chưa có nhà nào.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.lg,
                      AppSpacing.screen,
                      AppSpacing.navClearance,
                    ),
                    children: [
                      section(
                        'Thiết bị cần kiểm tra (${_selected.length}/$_maxDevices)',
                        devices.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Text(error.toString()),
                          data: (list) => list.isEmpty
                              ? const Text('Nhà chưa có thiết bị nào.')
                              : Column(
                                  children: [
                                    for (final device in list) ...[
                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        value: _selected.containsKey(device.id),
                                        onChanged: (_) => _toggle(device.id),
                                        title: Text(device.name),
                                        subtitle: device.subtitle == null
                                            ? null
                                            : Text(device.subtitle!),
                                      ),
                                      if (_selected[device.id] case final note?)
                                        TextField(
                                          controller: note,
                                          maxLength: 1000,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Mô tả lỗi (không bắt buộc)',
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                      section(
                        'Thông tin yêu cầu',
                        Column(
                          children: [
                            TextField(
                              controller: _title,
                              maxLength: 150,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Tiêu đề',
                                hintText: autoTitle,
                              ),
                            ),
                            TextField(
                              controller: _description,
                              maxLength: 2000,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả thêm',
                              ),
                            ),
                            TextField(
                              controller: _phone,
                              maxLength: 20,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại liên hệ',
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Mức ưu tiên',
                              ),
                              items: [
                                for (final entry
                                    in maintenancePriorityLabels.entries)
                                  DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _priority = value ?? 'NORMAL'),
                            ),
                          ],
                        ),
                      ),
                      section(
                        'Khung giờ bạn rảnh',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '07:00-21:00, cách hiện tại ít nhất 2 giờ, trong 14 ngày tới.',
                              style: theme.textTheme.bodySmall,
                            ),
                            SlotListEditor(
                              slots: _slots,
                              onChanged: (slots) =>
                                  setState(() => _slots = slots),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => _submit(
                                homeId,
                                _title.text.trim().isEmpty
                                    ? autoTitle
                                    : _title.text.trim(),
                              ),
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('Gửi yêu cầu'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
