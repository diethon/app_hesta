import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/theme.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, required this.home, required this.api, required this.currentUserId});
  final HomeSummary home;
  final HestaApi api;
  final String currentUserId;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Future<List<HomeMember>> _members;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _members = widget.api.members(widget.home.id));

  Future<void> _invite() async {
    final email = TextEditingController();
    final input = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Mời thành viên'),
      content: TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (để trống nếu chỉ lấy mã mời)')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, email.text.trim()), child: const Text('Tạo lời mời'))],
    ));
    email.dispose();
    if (input == null) return;
    try {
      final result = await widget.api.invite(widget.home.id, email: input.isEmpty ? null : input);
      if (!mounted) return;
      final code = asText(result['inviteCode']);
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('Lời mời đã tạo'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (result['emailSent'] == true) const Text('Lời mời đã được gửi tới email.'),
          if (input.isNotEmpty && result['emailSent'] != true) const Text('Email chưa gửi được. Bạn có thể chia sẻ mã bên dưới.'),
          const SizedBox(height: 8),
          const Text('Mã tham gia nhà:'),
          SelectableText(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ]),
        actions: [
          TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: code)); Navigator.pop(context); }, child: const Text('Sao chép mã')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _changeRole(HomeMember member) async {
    final role = member.role == 'OWNER' ? 'MEMBER' : 'OWNER';
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Đổi vai trò?'),
      content: Text('${member.name} sẽ trở thành ${role == 'OWNER' ? 'chủ nhà' : 'thành viên'}.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận'))],
    ));
    if (confirmed != true) return;
    try {
      await widget.api.updateMemberRole(widget.home.id, member.id, role);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _remove(HomeMember member) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text('Xóa ${member.name} khỏi nhà?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: HestaColors.error)))],
    ));
    if (confirmed != true) return;
    try {
      await widget.api.removeMember(widget.home.id, member.id);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<HomeMember>>(
    future: _members,
    builder: (context, snapshot) => Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Thành viên', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(widget.home.name, style: const TextStyle(color: HestaColors.muted)),
        ])),
        if (widget.home.isOwner) IconButton.filledTonal(tooltip: 'Mời thành viên', onPressed: _invite, icon: const Icon(Icons.person_add_alt_1_rounded)),
      ])),
      Expanded(child: snapshot.connectionState != ConnectionState.done
        ? const Center(child: CircularProgressIndicator())
        : snapshot.hasError
          ? _MembersMessage(message: snapshot.error.toString(), onRetry: _reload)
          : snapshot.data!.isEmpty
            ? _MembersMessage(message: 'Chưa có thành viên.', onRetry: _reload)
            : RefreshIndicator(onRefresh: () async { _reload(); await _members; }, child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final member = snapshot.data![index];
                  return Card(child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(backgroundColor: HestaColors.sidebar, child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase(), style: const TextStyle(color: HestaColors.primary))),
                    title: Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(member.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: widget.home.isOwner && member.id != widget.currentUserId
                      ? PopupMenuButton<String>(
                          tooltip: 'Quản lý ${member.name}',
                          onSelected: (value) { if (value == 'role') { _changeRole(member); } else { _remove(member); } },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'role', child: Text('Đổi vai trò')),
                            PopupMenuItem(value: 'remove', child: Text('Xóa khỏi nhà')),
                          ],
                        )
                      : Text(member.role == 'OWNER' ? 'Chủ nhà' : 'Thành viên', style: const TextStyle(color: HestaColors.muted, fontSize: 12)),
                  ));
                },
              )),
      ),
    ]),
  );
}

class _MembersMessage extends StatelessWidget {
  const _MembersMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.people_outline, color: HestaColors.primary, size: 42),
    const SizedBox(height: 10),
    Text(message, textAlign: TextAlign.center),
    TextButton(onPressed: onRetry, child: const Text('Làm mới')),
  ]));
}
