import 'package:flutter/material.dart';
import 'package:huinong_web/main.dart';
import 'package:huinong_web/models/user_model.dart';
import 'package:huinong_web/pages/register/register_page.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/user_api.dart';
import 'package:huinong_web/provider/app_provider.dart';

class LoginPage extends StatefulWidget {
  final String? username;
  const LoginPage({super.key, this.username});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  /// 初始化登录页面的状态。
  /// [初始化资源]
  /// 此方法在页面创建时调用，用于初始化用户名控制器。
  /// 如果 `widget.username` 不为空，将其设置为用户名控制器的文本。
  void initState() {
    super.initState(); 
    _usernameController = TextEditingController(text: widget.username);
  }

  @override
  /// 释放登录页面使用的资源。
  /// [清理资源]
  /// 此方法在页面销毁时调用，用于释放用户名控制器和密码控制器的资源。
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await UserApi.instance.login(
          _usernameController.text,
          _passwordController.text,
        );

        final user = User.fromJson(response['user']);
        final token = response['access_token'] as String;

        debugPrint('[LOGIN] 登录响应中的 elder_mode: ${user.elderMode}');
        debugPrint('[LOGIN] 准备调用 setUser, elderMode: ${user.elderMode}, token: ${token.substring(0, 10)}...');

        if (mounted) {
          Provider.of<AppProvider>(context, listen: false).setUser(user, token);
          debugPrint('[LOGIN] setUser 调用完成');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录失败: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          '登录',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          Switch(
            value: appProvider.isElderlyMode,
            onChanged: (value) {
              appProvider.toggleElderlyMode();
            },
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _usernameController,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    filled: true,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('登录'),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                      ModalRoute.withName('/'),
                    );
                  },
                  child: const Text('没有账号？立即注册'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
