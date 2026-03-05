import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/profile_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideCurrent = true, _hideNew = true, _hideConfirm = true;
  bool _loading = false;
  String? _error;

  Future<void> _changePassword() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final memberId = auth.memberId;

    if (memberId == null) return _setError('User not logged in');

    final current = _currentCtrl.text.trim();
    final next = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if ([current, next, confirm].any((e) => e.isEmpty)) {
      return _setError('All fields are required');
    }
    if (next != confirm) {
      return _setError('New password and confirmation do not match');
    }
    if (next.length < 6) {
      return _setError('New password must be at least 6 characters long');
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await profile.changePassword(
      memberId: memberId,
      currentPassword: current,
      newPassword: next,
      confirmPassword: confirm,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (!success) {
      return _setError(profile.error ?? 'Failed to change password');
    }

    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changed successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _setError(String msg) {
    setState(() => _error = msg);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: themeProvider.getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.getIconColor()),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: themeProvider.getBackgroundColor(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _passwordField(
              'Current Password',
              _currentCtrl,
              _hideCurrent,
              () => setState(() => _hideCurrent = !_hideCurrent),
              themeProvider,
            ),
            const SizedBox(height: 20),
            _passwordField(
              'New Password',
              _newCtrl,
              _hideNew,
              () => setState(() => _hideNew = !_hideNew),
              themeProvider,
            ),
            const SizedBox(height: 20),
            _passwordField(
              'Confirm New Password',
              _confirmCtrl,
              _hideConfirm,
              () => setState(() => _hideConfirm = !_hideConfirm),
              themeProvider,
            ),
            const SizedBox(height: 20),
            if (_error != null) _errorBox(_error!),
            const SizedBox(height: 20),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(
    String label,
    TextEditingController ctrl,
    bool obscure,
    VoidCallback toggle,
    ThemeProvider themeProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: themeProvider.getTextColor(),
            )),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: TextStyle(color: themeProvider.getTextColor()),
          decoration: InputDecoration(
            filled: true,
            fillColor: themeProvider.getSurfaceColor(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Text(msg, style: TextStyle(color: Colors.red.shade800)),
    );
  }

  Widget _saveButton() {
    return GradientButton(
      label: 'Save Password',
      onPressed: _changePassword,
      isLoading: _loading,
    );
  }
}
