import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'device_screen.dart';
import 'members_screen.dart';
import 'scenes_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});
  final SessionController session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  List<HomeSummary>? _homes;
  HomeSummary? _selected;
  Future<List<Device>>? _devices;
  String? _error;
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  Future<void> _loadHomes() async {
    setState(() { _loading = true; _error = null; });
    try {
      final homes = await widget.session.api.homes();
      if (!mounted) return;
      final previousId = _selected?.id;
      HomeSummary? selected = homes.isEmpty ? null : homes.first;
      for (final home in homes) {
        if (home.id == previousId) { selected = home; break; }
      }
      setState(() {
        _homes = homes;
        _selected = selected;
        _devices = selected == null ? null : widget.session.api.devices(selected.id);
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = error.toString(); _loading = false; });
    }
  }

  void _selectHome(HomeSummary home) {
    if (home.id == _selected?.id) return;
    setState(() {
      _selected = home;
      _devices = widget.session.api.devices(home.id);
    });
  }

  Future<void> _refreshDevices() async {
    final home = _selected;
    if (home == null) return;
    setState(() => _devices = widget.session.api.devices(home.id));
    try { await _devices; } catch (_) { /* FutureBuilder shows the error. */ }
  }

  Future<void> _homeAction({required bool create}) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(create ? 'Tạo nhà mới' : 'Tham gia nhà'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: create ? 150 : null,
          decoration: InputDecoration(labelText: create ? 'Tên ngôi nhà' : 'Mã hoặc token lời mời'),
          onSubmitted: (_) => Navigator.pop(context, controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(create ? 'Tạo nhà' : 'Tham gia')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    try {
      if (create) {
        _selected = await widget.session.api.createHome(value);
      } else {
        await widget.session.api.joinHome(value);
        _selected = null;
      }
      await _loadHomes();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(create ? 'Đã tạo nhà.' : 'Đã tham gia nhà.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final home = _selected;
    final titles = ['Tổng quan', 'Thiết bị', 'Kịch bản', 'Thành viên', 'Tài khoản'];
    final destinations = const [
      NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Tổng quan'),
      NavigationDestination(icon: Icon(Icons.devices_other_outlined), selectedIcon: Icon(Icons.devices_rounded), label: 'Thiết bị'),
      NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Kịch bản'),
      NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: 'Thành viên'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Tài khoản'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.home_rounded, color: HestaColors.primary),
          const SizedBox(width: 8),
          const Text('HESTA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.3)),
          if (wide) ...[const SizedBox(width: 14), Text(' / ${titles[_tab]}', style: const TextStyle(fontSize: 16, color: HestaColors.muted))],
        ]),
        actions: [
          IconButton(tooltip: 'Làm mới', onPressed: _loading ? null : () { if (_tab <= 1) { _refreshDevices(); } else { _loadHomes(); } }, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (wide) NavigationRail(
          backgroundColor: HestaColors.sidebar,
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          labelType: NavigationRailLabelType.all,
          destinations: destinations.map((item) => NavigationRailDestination(icon: item.icon, selectedIcon: item.selectedIcon, label: Text(item.label))).toList(),
        ),
        Expanded(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: _loading && _homes == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _homes == null
                  ? _ErrorState(message: _error!, onRetry: _loadHomes)
                  : _tab == 4
                      ? _AccountView(session: widget.session)
                      : Column(children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Row(children: [
                              Expanded(child: home == null
                                  ? const Text('Chưa có ngôi nhà', style: TextStyle(fontWeight: FontWeight.w700))
                                  : DropdownButtonHideUnderline(child: DropdownButton<HomeSummary>(
                                      value: home,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      items: _homes!.map((item) => DropdownMenuItem(value: item, child: Text(item.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                                      onChanged: (value) { if (value != null) _selectHome(value); },
                                    ))),
                              PopupMenuButton<String>(
                                tooltip: 'Quản lý nhà',
                                icon: const Icon(Icons.add_circle_outline_rounded, color: HestaColors.primary),
                                onSelected: (action) => _homeAction(create: action == 'create'),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'create', child: Text('Tạo nhà mới')),
                                  PopupMenuItem(value: 'join', child: Text('Tham gia bằng mã mời')),
                                ],
                              ),
                            ]),
                          ),
                          Expanded(child: home == null
                              ? _EmptyHome(onCreate: () => _homeAction(create: true), onJoin: () => _homeAction(create: false))
                              : switch (_tab) {
                                  0 => _Overview(home: home, user: widget.session.user!, devices: _devices!, onDevices: () => setState(() => _tab = 1), onRefresh: _refreshDevices),
                                  1 => DeviceScreen(key: ValueKey(home.id), home: home, api: widget.session.api, devices: _devices!, onRefresh: _refreshDevices),
                                  2 => ScenesScreen(key: ValueKey(home.id), home: home, api: widget.session.api),
                                  _ => MembersScreen(key: ValueKey(home.id), home: home, api: widget.session.api, currentUserId: widget.session.user!.id),
                                }),
                        ]),
        ))),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: _tab,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: destinations,
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.home, required this.user, required this.devices, required this.onDevices, required this.onRefresh});
  final HomeSummary home;
  final HestaUser user;
  final Future<List<Device>> devices;
  final VoidCallback onDevices;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [HestaColors.sidebar, HestaColors.successSoft]),
          border: Border.all(color: HestaColors.line),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.wb_sunny_outlined, color: HestaColors.primary, size: 30),
          const SizedBox(height: 14),
          Text('Xin chào, ${user.fullName.split(' ').last}!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Chào mừng về ${home.name}.', style: const TextStyle(color: HestaColors.muted)),
        ]),
      ),
      const SizedBox(height: 24),
      Text('Nhà của bạn', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      FutureBuilder<List<Device>>(
        future: devices,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
          if (snapshot.hasError) return _ErrorState(message: snapshot.error.toString(), onRetry: onRefresh);
          final items = snapshot.data ?? const <Device>[];
          final online = items.where((device) => device.isOnline).length;
          return Column(children: [
            Row(children: [
              Expanded(child: _StatCard(icon: Icons.devices_other_rounded, label: 'Thiết bị', value: '${items.length}', color: HestaColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.wifi_rounded, label: 'Đang kết nối', value: '$online', color: HestaColors.mint)),
            ]),
            const SizedBox(height: 20),
            Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: const CircleAvatar(backgroundColor: HestaColors.sidebar, child: Icon(Icons.devices_rounded, color: HestaColors.primary)),
              title: const Text('Thiết bị trong nhà'),
              subtitle: Text(items.isEmpty ? 'Chưa có thiết bị nào' : '${items.length} thiết bị · $online đang kết nối'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onDevices,
            )),
          ]);
        },
      ),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: color),
    const SizedBox(height: 12),
    Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: HestaColors.muted)),
  ])));
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onCreate, required this.onJoin});
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.home_work_outlined, size: 60, color: HestaColors.primary),
    const SizedBox(height: 16),
    Text('Bắt đầu với ngôi nhà của bạn', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    const Text('Tạo nhà mới hoặc nhập mã mời để tham gia.', textAlign: TextAlign.center, style: TextStyle(color: HestaColors.muted)),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: onCreate, child: const Text('Tạo nhà')),
    TextButton(onPressed: onJoin, child: const Text('Tôi có mã mời')),
  ])));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_outlined, color: HestaColors.error, size: 40),
    const SizedBox(height: 12),
    Text(message, textAlign: TextAlign.center),
    TextButton(onPressed: onRetry, child: const Text('Thử lại')),
  ])));
}

class _AccountView extends StatelessWidget {
  const _AccountView({required this.session});
  final SessionController session;

  Future<void> _edit(BuildContext context) async {
    final name = TextEditingController(text: session.user!.fullName);
    final phone = TextEditingController(text: session.user!.phoneNumber ?? '');
    final value = await showDialog<(String, String)>(context: context, builder: (context) => AlertDialog(
      title: const Text('Chỉnh sửa hồ sơ'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, autofocus: true, maxLength: 150, decoration: const InputDecoration(labelText: 'Họ và tên')),
        const SizedBox(height: 12),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, (name.text.trim(), phone.text.trim())), child: const Text('Lưu'))],
    ));
    name.dispose();
    phone.dispose();
    if (value == null || value.$1.isEmpty) return;
    try {
      final user = await session.api.updateProfile(value.$1, value.$2.isEmpty ? null : value.$2);
      await session.updateUser(user);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final value = await showDialog<(String, String)>(context: context, builder: (context) => AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại')),
        const SizedBox(height: 12),
        TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu mới (ít nhất 6 ký tự)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, (current.text, next.text)), child: const Text('Lưu'))],
    ));
    current.dispose();
    next.dispose();
    if (value == null) return;
    if (value.$1.isEmpty || value.$2.length < 6) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu mới cần ít nhất 6 ký tự.')));
      return;
    }
    try {
      await session.api.changePassword(value.$1, value.$2);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = session.user!;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        CircleAvatar(radius: 34, backgroundColor: HestaColors.sidebar, child: Text(user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 28, color: HestaColors.primary))),
        const SizedBox(height: 12),
        Text(user.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(user.email, style: const TextStyle(color: HestaColors.muted)),
      ]))),
      const SizedBox(height: 16),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Chỉnh sửa hồ sơ'), trailing: const Icon(Icons.chevron_right), onTap: () => _edit(context)),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Đổi mật khẩu'), trailing: const Icon(Icons.chevron_right), onTap: () => _changePassword(context)),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.logout_rounded, color: HestaColors.error), title: const Text('Đăng xuất'), onTap: session.signOut),
      ])),
    ]);
  }
}
