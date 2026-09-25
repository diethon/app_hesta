import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';

enum _AuthMode { login, register, forgot, reset }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.session});
  final SessionController session;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  final _invite = TextEditingController();
  _AuthMode _mode = _AuthMode.login;
  bool _busy = false;
  bool _showPassword = false;
  bool _otpVerified = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _otp, _invite]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _switch(_AuthMode mode) => setState(() {
    _mode = mode;
    _error = null;
  });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      switch (_mode) {
        case _AuthMode.login:
          await widget.session.signIn(_email.text.trim(), _password.text);
          break;
        case _AuthMode.register:
          await widget.session.api.register(_name.text.trim(), _email.text.trim(), _password.text, inviteCode: _invite.text.trim());
          if (!mounted) return;
          _password.clear();
          _switch(_AuthMode.login);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công. Hãy đăng nhập.')));
          break;
        case _AuthMode.forgot:
          await widget.session.api.forgotPassword(_email.text.trim());
          if (!mounted) return;
          _switch(_AuthMode.reset);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã OTP đã được gửi tới email.')));
          break;
        case _AuthMode.reset:
          if (!_otpVerified) {
            await widget.session.api.verifyOtp(_email.text.trim(), _otp.text.trim());
            if (mounted) setState(() => _otpVerified = true);
          } else {
            await widget.session.api.resetPassword(_email.text.trim(), _otp.text.trim(), _password.text);
            if (!mounted) return;
            _password.clear();
            _otp.clear();
            _otpVerified = false;
            _switch(_AuthMode.login);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công.')));
          }
          break;
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      _AuthMode.login => 'Chào mừng trở lại',
      _AuthMode.register => 'Tạo tài khoản HESTA',
      _AuthMode.forgot => 'Quên mật khẩu?',
      _AuthMode.reset => 'Đặt lại mật khẩu',
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const _BrandMark(),
                const SizedBox(height: 30),
                if (widget.session.api.baseUrl.isEmpty) ...[
                  const Text('Chưa cấu hình máy chủ. Thiết lập API_BASE_URL khi chạy ứng dụng.', textAlign: TextAlign.center, style: TextStyle(color: HestaColors.error)),
                  const SizedBox(height: 16),
                ],
                Card(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_mode == _AuthMode.login ? 'Quản lý ngôi nhà của bạn, mọi lúc mọi nơi.' : 'Một ngôi nhà thông minh bắt đầu từ đây.', style: const TextStyle(color: HestaColors.muted)),
                    const SizedBox(height: 24),
                    if (_mode == _AuthMode.register) ...[
                      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Họ và tên'), textCapitalization: TextCapitalization.words, validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null),
                      const SizedBox(height: 14),
                    ],
                    if (_mode != _AuthMode.reset) ...[
                      TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], validator: (v) => v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? 'Email không hợp lệ' : null),
                      const SizedBox(height: 14),
                    ] else ...[
                      Text('Mã xác minh gửi đến ${_email.text.trim()}', style: const TextStyle(color: HestaColors.muted)),
                      const SizedBox(height: 14),
                      TextFormField(controller: _otp, decoration: const InputDecoration(labelText: 'Mã OTP'), keyboardType: TextInputType.number, validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mã OTP' : null),
                      const SizedBox(height: 14),
                    ],
                    if (_mode == _AuthMode.login || _mode == _AuthMode.register || (_mode == _AuthMode.reset && _otpVerified)) ...[
                      TextFormField(controller: _password, obscureText: !_showPassword, decoration: InputDecoration(labelText: _mode == _AuthMode.reset ? 'Mật khẩu mới' : 'Mật khẩu', suffixIcon: IconButton(tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu', icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _showPassword = !_showPassword))), validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : (_mode != _AuthMode.login && v.length < 8 ? 'Ít nhất 8 ký tự' : null)),
                      const SizedBox(height: 14),
                    ],
                    if (_mode == _AuthMode.register) ...[
                      TextFormField(controller: _invite, decoration: const InputDecoration(labelText: 'Mã mời (nếu có)')),
                      const SizedBox(height: 14),
                    ],
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: HestaColors.error)),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(switch (_mode) { _AuthMode.login => 'Đăng nhập', _AuthMode.register => 'Đăng ký', _AuthMode.forgot => 'Gửi mã OTP', _AuthMode.reset => _otpVerified ? 'Đổi mật khẩu' : 'Xác minh OTP' })),
                    const SizedBox(height: 12),
                    if (_mode == _AuthMode.login) ...[
                      TextButton(onPressed: _busy ? null : () => _switch(_AuthMode.forgot), child: const Text('Quên mật khẩu?')),
                      TextButton(onPressed: _busy ? null : () => _switch(_AuthMode.register), child: const Text('Chưa có tài khoản? Đăng ký')),
                    ] else TextButton(onPressed: _busy ? null : () => _switch(_AuthMode.login), child: const Text('Quay lại đăng nhập')),
                  ])),
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: HestaColors.sidebar, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.home_rounded, color: HestaColors.primary, size: 32)),
    const SizedBox(width: 12),
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('HESTA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2, color: HestaColors.text)),
      Text('Ngôi nhà của bạn, trong tầm tay', style: TextStyle(color: HestaColors.muted, fontSize: 12)),
    ]),
  ]);
}
