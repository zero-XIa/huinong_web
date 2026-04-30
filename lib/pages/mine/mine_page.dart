import 'package:flutter/material.dart';
import 'package:huinong_web/api/user_api.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/models/user_model.dart';
import 'package:huinong_web/provider/app_provider.dart';
import 'package:huinong_web/utils/error_handler.dart';
import 'package:huinong_web/components/change_password_dialog.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = Provider.of<AppProvider>(context, listen: false).currentUser;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await UserApi.instance.getCurrentUser();
      if (!mounted) return;
      Provider.of<AppProvider>(context, listen: false).updateUser(user);
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      debugPrint('刷新用户信息失败: $e');
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '未绑定';
    }
    if (phone.length >= 11) {
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    }
    return phone;
  }

  void _showChangePhoneDialog() {
    final TextEditingController phoneController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                '修改手机号',
                style: theme.textTheme.titleLarge,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '新手机号',
                        hintText: '请输入11位手机号',
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                          final newPhone = phoneController.text.trim();
                          if (!RegExp(r'^1\d{10}$').hasMatch(newPhone)) {
                            ErrorHandler.showErrorSnackBar(ctx, '请输入有效的11位手机号');
                            return;
                          }

                          setState(() => isLoading = true);
                          try {
                            final updatedUser = await UserApi.instance.updateUser(phone: newPhone);
                            if (!ctx.mounted) {
                              setState(() => isLoading = false);
                              return;
                            }
                            Provider.of<AppProvider>(ctx, listen: false).updateUser(updatedUser);
                            setState(() => _currentUser = updatedUser);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('手机号修改成功')),
                            );
                          } catch (e) {
                            if (!ctx.mounted) {
                              setState(() => isLoading = false);
                              return;
                            }
                            ErrorHandler.showErrorSnackBar(ctx, e);
                          }
                          setState(() => isLoading = false);
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (!mounted) return;
      await Provider.of<AppProvider>(context, listen: false).logout();
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '我的',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? Center(
                  child: Text(
                    '未能加载用户信息',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '个人信息',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(context, '用户名', _currentUser!.username),
                              _buildInfoRow(context, '手机号', _maskPhone(_currentUser!.phone)),
                              _buildInfoRow(context, '注册时间', _currentUser!.formattedCreateTime),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          title: Text(
                            '修改手机号',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _showChangePhoneDialog,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          title: Text(
                            '修改密码',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => ChangePasswordDialog.show(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '长辈模式',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: appProvider.isElderlyMode,
                                onChanged: (value) {
                                  appProvider.updateElderMode(value, context);
                                },
                                activeTrackColor: theme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStateProperty.all(Colors.red),
                          ),
                          child: Text(
                            '退出登录',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
