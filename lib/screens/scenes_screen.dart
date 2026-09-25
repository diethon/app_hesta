import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/theme.dart';

class ScenesScreen extends StatefulWidget {
  const ScenesScreen({super.key, required this.home, required this.api});
  final HomeSummary home;
  final HestaApi api;

  @override
  State<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends State<ScenesScreen> {
  late Future<List<HomeScene>> _scenes;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _scenes = widget.api.scenes(widget.home.id));

  Future<void> _create() async {
    final name = TextEditingController();
    final description = TextEditingController();
    final input = await showDialog<(String, String)>(context: context, builder: (context) => AlertDialog(
      title: const Text('Tạo kịch bản'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, autofocus: true, maxLength: 150, decoration: const InputDecoration(labelText: 'Tên kịch bản')),
        const SizedBox(height: 12),
        TextField(controller: description, maxLines: 2, maxLength: 2000, decoration: const InputDecoration(labelText: 'Mô tả (nếu có)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, (name.text.trim(), description.text.trim())), child: const Text('Tạo'))],
    ));
    name.dispose();
    description.dispose();
    if (input == null || input.$1.isEmpty) return;
    try {
      await widget.api.createScene(widget.home.id, input.$1, input.$2);
      if (mounted) {
        _reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo kịch bản.')));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _delete(HomeScene scene) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text('Xóa “${scene.name}”?'),
      content: const Text('Kịch bản và các hành động của nó sẽ bị xóa.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: HestaColors.error)))],
    ));
    if (confirmed != true) return;
    try {
      await widget.api.deleteScene(widget.home.id, scene.id);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _toggle(HomeScene scene, bool value) async {
    try {
      await widget.api.updateScene(widget.home.id, scene, enabled: value);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _open(HomeScene scene) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SceneDetails(home: widget.home, api: widget.api, sceneId: scene.id),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<HomeScene>>(
    future: _scenes,
    builder: (context, snapshot) {
      final scenes = snapshot.data;
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kịch bản', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Text('Tự động hóa theo ý bạn', style: TextStyle(color: HestaColors.muted)),
          ])),
          if (widget.home.isOwner) IconButton.filledTonal(tooltip: 'Tạo kịch bản', onPressed: _create, icon: const Icon(Icons.add_rounded)),
        ])),
        Expanded(child: snapshot.connectionState != ConnectionState.done
          ? const Center(child: CircularProgressIndicator())
          : snapshot.hasError
            ? _SceneMessage(message: snapshot.error.toString(), onRetry: _reload)
            : scenes!.isEmpty
              ? _SceneMessage(message: 'Chưa có kịch bản nào.', onRetry: _reload)
              : RefreshIndicator(onRefresh: () async { _reload(); await _scenes; }, child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: scenes.length,
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    return Card(child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(backgroundColor: HestaColors.sidebar, child: Icon(Icons.auto_awesome, color: HestaColors.primary)),
                      title: Text(scene.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${scene.actionCount} hành động · ${scene.enabled ? 'Đang bật' : 'Đang tắt'}${scene.description?.isNotEmpty == true ? '\n${scene.description}' : ''}', maxLines: 3, overflow: TextOverflow.ellipsis),
                      isThreeLine: scene.description?.isNotEmpty == true,
                      trailing: widget.home.isOwner ? PopupMenuButton<String>(
                        tooltip: 'Tùy chọn ${scene.name}',
                        onSelected: (value) { if (value == 'delete') { _delete(scene); } else { _toggle(scene, !scene.enabled); } },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'toggle', child: Text(scene.enabled ? 'Tắt kịch bản' : 'Bật kịch bản')),
                          const PopupMenuItem(value: 'delete', child: Text('Xóa kịch bản')),
                        ],
                      ) : const Icon(Icons.chevron_right_rounded),
                      onTap: () => _open(scene),
                    ));
                  },
                )),
        ),
      ]);
    },
  );
}

class _SceneDetails extends StatefulWidget {
  const _SceneDetails({required this.home, required this.api, required this.sceneId});
  final HomeSummary home;
  final HestaApi api;
  final String sceneId;

  @override
  State<_SceneDetails> createState() => _SceneDetailsState();
}

class _SceneDetailsState extends State<_SceneDetails> {
  late Future<JsonMap> _scene;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _scene = widget.api.scene(widget.home.id, widget.sceneId));

  Future<void> _add(int order) async {
    List<Device> devices;
    try {
      devices = await widget.api.devices(widget.home.id);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!mounted) return;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhà chưa có thiết bị để thêm hành động.')));
      return;
    }
    String deviceId = devices.first.id;
    String action = 'TURN_ON';
    final input = await showDialog<(String, String)>(context: context, builder: (context) => StatefulBuilder(builder: (context, update) => AlertDialog(
      title: const Text('Thêm hành động'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: deviceId, decoration: const InputDecoration(labelText: 'Thiết bị'), items: devices.map((device) => DropdownMenuItem(value: device.id, child: Text(device.name, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) { if (value != null) update(() => deviceId = value); }),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: action, decoration: const InputDecoration(labelText: 'Hành động'), items: const [DropdownMenuItem(value: 'TURN_ON', child: Text('Bật')), DropdownMenuItem(value: 'TURN_OFF', child: Text('Tắt'))], onChanged: (value) { if (value != null) update(() => action = value); }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, (deviceId, action)), child: const Text('Thêm'))],
    )));
    if (input == null) return;
    try {
      await widget.api.addSceneAction(widget.home.id, widget.sceneId, input.$1, input.$2, order);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _remove(String actionId) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Xóa hành động?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: HestaColors.error)))],
    ));
    if (confirmed != true) return;
    try {
      await widget.api.removeSceneAction(widget.home.id, widget.sceneId, actionId);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: FractionallySizedBox(heightFactor: 0.75, child: FutureBuilder<JsonMap>(
    future: _scene,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return Center(child: snapshot.hasError ? Text(snapshot.error.toString()) : const CircularProgressIndicator());
      final scene = snapshot.data!;
      final actions = asMapList(scene['actions']);
      return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
        Row(children: [
          const Icon(Icons.auto_awesome, color: HestaColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(asText(scene['name']), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          IconButton(tooltip: 'Đóng', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 8),
        if (asText(scene['description']).isNotEmpty) Text(asText(scene['description']), style: const TextStyle(color: HestaColors.muted)),
        const SizedBox(height: 18),
        Text('Hành động (${actions.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (actions.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Chưa có hành động nào.', style: TextStyle(color: HestaColors.muted))),
        ...actions.map((item) => Card(child: ListTile(
          leading: const Icon(Icons.bolt_rounded, color: HestaColors.primary),
          title: Text(asText(item['targetDeviceName'])),
          subtitle: Text(switch (asText(item['action'])) { 'TURN_ON' => 'Bật', 'TURN_OFF' => 'Tắt', final value => value }),
          trailing: widget.home.isOwner ? IconButton(tooltip: 'Xóa hành động', onPressed: () => _remove(asText(item['id'])), icon: const Icon(Icons.delete_outline, color: HestaColors.error)) : null,
        ))),
        if (widget.home.isOwner) ...[const SizedBox(height: 12), ElevatedButton.icon(onPressed: () => _add(actions.length), icon: const Icon(Icons.add), label: const Text('Thêm hành động'))],
      ]);
    },
  )));
}

class _SceneMessage extends StatelessWidget {
  const _SceneMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.auto_awesome_outlined, color: HestaColors.primary, size: 42),
    const SizedBox(height: 10),
    Text(message, textAlign: TextAlign.center),
    TextButton(onPressed: onRetry, child: const Text('Làm mới')),
  ]));
}
