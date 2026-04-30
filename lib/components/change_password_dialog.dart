import 'package:flutter/material.dart';
import '../api/user_api.dart';
import '../utils/error_handler.dart';
import '../provider/app_provider.dart';
import 'package:provider/provider.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const ChangePasswordDialog(),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  bool _validatePassword(String password) {
    return RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]{8,20}$').hasMatch(password);
  }

  Future<void> _handleSubmit() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, '请填写完整信息');
      return;
    }

    if (!_validatePassword(newPassword)) {
      ErrorHandler.showErrorSnackBar(context, '新密码需8-20位，且包含字母和数字');
      return;
    }

    if (newPassword != confirmPassword) {
      ErrorHandler.showErrorSnackBar(context, '两次输入的密码不一致');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await UserApi.instance.changePassword(oldPassword, newPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已修改，请重新登录')),
      );

      await Future.delayed(const Duration(milliseconds: 1500));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AppProvider>(context, listen: false).logout();
      });
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isElderMode = Provider.of<AppProvider>(context, listen: false).isElderlyMode;

    return AlertDialog(
      title: Text('修改密码', style: theme.textTheme.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '原密码'),
              style: theme.textTheme.bodyLarge,
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '新密码',
                hintText: '8-20位，包含字母和数字',
              ),
              style: theme.textTheme.bodyLarge,
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '确认新密码'),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: isElderMode
              ? TextButton.styleFrom(
                  minimumSize: const Size(80, 50),
                  textStyle: const TextStyle(fontSize: 18),
                )
              : null,
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: isElderMode
              ? ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 50),
                  textStyle: const TextStyle(fontSize: 18),
                )
              : null,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('确认'),
        ),
      ],
    );
  }
}