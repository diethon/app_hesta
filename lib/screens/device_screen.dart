import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/theme.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.home, required this.api, required this.devices, required this.onRefresh});
  final HomeSummary home;
  final HestaApi api;
  final Future<List<Device>> devices;
  final Future<void> Function() onRefresh;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  String? _roomId;
  late Future<List<Room>> _rooms;

  @override
  void initState() {
    super.initState();
    _rooms = widget.api.rooms(widget.home.id);
  }

  Future<void> _openDevice(Device device) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DeviceDetails(api: widget.api, deviceId: device.id, owner: widget.home.isOwner, onRemoved: widget.onRefresh),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Device>>(
    future: widget.devices,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _DeviceMessage(message: snapshot.error.toString(), onRetry: widget.onRefresh);
      final all = snapshot.data ?? const <Device>[];
      final filtered = _roomId == null ? all : all.where((device) => device.roomId == _roomId).toList(growable: false);
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Thiết bị', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('${all.length} thiết bị trong ${widget.home.name}', style: const TextStyle(color: HestaColors.muted)),
          ])),
        ])),
        FutureBuilder<List<Room>>(
          future: _rooms,
          builder: (context, roomSnapshot) {
            if (!roomSnapshot.hasData || roomSnapshot.data!.isEmpty) return const SizedBox.shrink();
            return SizedBox(height: 54, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Tất cả'), selected: _roomId == null, onSelected: (_) => setState(() => _roomId = null))),
              ...roomSnapshot.data!.map((room) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(room.name), selected: _roomId == room.id, onSelected: (_) => setState(() => _roomId = room.id)))),
            ]));
          },
        ),
        Expanded(child: filtered.isEmpty
          ? _DeviceMessage(message: all.isEmpty ? 'Chưa có thiết bị nào trong nhà.' : 'Phòng này chưa có thiết bị.', onRetry: widget.onRefresh)
          : RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final device = filtered[index];
                  return Card(child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(backgroundColor: HestaColors.sidebar, child: Icon(_iconFor(device.type), color: HestaColors.primary)),
                    title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(device.roomName?.isNotEmpty == true ? device.roomName! : 'Chưa gán phòng', style: const TextStyle(color: HestaColors.muted)),
                      if (device.state.isNotEmpty) Text(_stateLabel(device.state), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: HestaColors.muted)),
                    ]),
                    trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: device.isOnline ? HestaColors.successSoft : HestaColors.offSoft, borderRadius: BorderRadius.circular(20)), child: Text(device.isOnline ? 'Online' : 'Offline', style: TextStyle(fontSize: 11, color: device.isOnline ? HestaColors.text : HestaColors.muted))),
                    onTap: () => _openDevice(device),
                  ));
                },
              ),
            )),
      ]);
    },
  );
}

IconData _iconFor(String type) {
  final value = type.toUpperCase();
  if (value.contains('LIGHT') || value.contains('BULB')) return Icons.lightbulb_outline_rounded;
  if (value.contains('LOCK')) return Icons.lock_outline_rounded;
  if (value.contains('TEMP') || value.contains('SENSOR')) return Icons.thermostat_rounded;
  if (value.contains('FAN')) return Icons.air_rounded;
  return Icons.power_outlined;
}

String _stateLabel(JsonMap state) => state.entries.take(3).map((entry) => '${entry.key}: ${entry.value}').join(' · ');

class _DeviceMessage extends StatelessWidget {
  const _DeviceMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.devices_other_outlined, color: HestaColors.primary, size: 42),
    const SizedBox(height: 10),
    Text(message, textAlign: TextAlign.center),
    TextButton(onPressed: onRetry, child: const Text('Làm mới')),
  ]));
}

class _DeviceDetails extends StatefulWidget {
  const _DeviceDetails({required this.api, required this.deviceId, required this.owner, required this.onRemoved});
  final HestaApi api;
  final String deviceId;
  final bool owner;
  final Future<void> Function() onRemoved;

  @override
  State<_DeviceDetails> createState() => _DeviceDetailsState();
}

class _DeviceDetailsState extends State<_DeviceDetails> {
  late Future<Device> _device;
  late Future<List<JsonMap>> _history;

  @override
  void initState() {
    super.initState();
    _device = widget.api.device(widget.deviceId);
    _history = widget.api.deviceHistory(widget.deviceId);
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Xóa thiết bị?'),
      content: const Text('Thiết bị sẽ bị xóa khỏi ngôi nhà này.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: HestaColors.error)))],
    ));
    if (confirmed != true) return;
    try {
      await widget.api.request('DELETE', '/devices/${widget.deviceId}');
      await widget.onRemoved();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: FractionallySizedBox(
    heightFactor: 0.82,
    child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: FutureBuilder<Device>(
      future: _device,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: snapshot.hasError ? Text(snapshot.error.toString()) : const CircularProgressIndicator());
        final device = snapshot.data!;
        return ListView(children: [
          Row(children: [
            CircleAvatar(backgroundColor: HestaColors.sidebar, child: Icon(_iconFor(device.type), color: HestaColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Text(device.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
            IconButton(tooltip: 'Đóng', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 16),
          Card(child: Column(children: [
            ListTile(title: const Text('Trạng thái'), trailing: Text(device.isOnline ? 'Đang kết nối' : device.status)),
            ListTile(title: const Text('Phòng'), trailing: Text(device.roomName ?? 'Chưa gán')),
            ListTile(title: const Text('Loại'), trailing: Text(device.type)),
            if (device.lastSeen != null) ListTile(title: const Text('Hoạt động gần nhất'), subtitle: Text(device.lastSeen!)),
          ])),
          const SizedBox(height: 16),
          Text('Dữ liệu hiện tại', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (device.state.isEmpty) const Text('Chưa có dữ liệu trạng thái.', style: TextStyle(color: HestaColors.muted))
          else Card(child: Column(children: device.state.entries.map((entry) => ListTile(dense: true, title: Text(entry.key), trailing: Text('${entry.value}'))).toList())),
          const SizedBox(height: 16),
          Text('Lịch sử', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          FutureBuilder<List<JsonMap>>(future: _history, builder: (context, history) {
            if (!history.hasData) return Padding(padding: const EdgeInsets.all(16), child: history.hasError ? Text(history.error.toString()) : const Center(child: CircularProgressIndicator()));
            if (history.data!.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Chưa có lịch sử.', style: TextStyle(color: HestaColors.muted)));
            return Column(children: history.data!.take(20).map((entry) => Card(child: ListTile(
              title: Text(asText(entry['changedAt'])),
              subtitle: Text(_stateLabel(asMap(entry['newState'])), maxLines: 2, overflow: TextOverflow.ellipsis),
            ))).toList());
          }),
          if (widget.owner) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: _remove, icon: const Icon(Icons.delete_outline, color: HestaColors.error), label: const Text('Xóa thiết bị', style: TextStyle(color: HestaColors.error))),
          ],
        ]);
      },
    )),
  ));
}
