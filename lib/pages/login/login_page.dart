import 'package:flutter/material.dart';
import 'package:huinong_web/main.dart';
import 'package:huinong_web/pages/register/register_page.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/user_api.dart';
import 'package:huinong_web/provider/app_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await UserApi.instance.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (mounted) {
          Provider.of<AppProvider>(context, listen: false).setUser(user);
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
    final isElderMode = appProvider.isElderlyMode;

    // Conditional Styling
    final double inputFontSize = isElderMode ? 18.0 : 14.0;
    final double buttonFontSize = isElderMode ? 19.0 : 16.0;
    final double linkFontSize = isElderMode ? 16.0 : 14.0;
    final double elementSpacing = isElderMode ? 24.0 : 16.0;
    final double buttonHeight = isElderMode ? 56.0 : 44.0;
    final BorderRadius borderRadius = BorderRadius.circular(isElderMode ? 12.0 : 8.0);
    final Color inputTextColor = isElderMode ? const Color(0xFF333333) : Colors.black;
    final Color inputFillColor = isElderMode ? const Color(0xFFF5F5DC) : Colors.grey[200]!;
    final EdgeInsets inputPadding = EdgeInsets.symmetric(vertical: isElderMode ? 18 : 12, horizontal: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text('登录', style: TextStyle(fontSize: isElderMode ? 22 : 18)),
        actions: [
          Switch(
            value: isElderMode,
            onChanged: (value) {
              appProvider.toggleElderlyMode();
            },
          ),
        ],
      ),
      backgroundColor: isElderMode ? const Color(0xFFF5F5DC) : null,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(elementSpacing),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(fontSize: inputFontSize, color: inputTextColor),
                  decoration: InputDecoration(
                    labelText: '用户名',
                    labelStyle: TextStyle(fontSize: inputFontSize, color: inputTextColor.withAlpha(179)),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide.none),
                    contentPadding: inputPadding,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    return null;
                  },
                ),
                SizedBox(height: elementSpacing),
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(fontSize: inputFontSize, color: inputTextColor),
                  decoration: InputDecoration(
                    labelText: '密码',
                    labelStyle: TextStyle(fontSize: inputFontSize, color: inputTextColor.withAlpha(179)),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide.none),
                    contentPadding: inputPadding,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),
                SizedBox(height: elementSpacing * 1.5),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: borderRadius),
                          ),
                          child: Text('登录', style: TextStyle(fontSize: buttonFontSize)),
                        ),
                      ),
                SizedBox(height: elementSpacing),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: Text('没有账号？立即注册', style: TextStyle(fontSize: linkFontSize)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
