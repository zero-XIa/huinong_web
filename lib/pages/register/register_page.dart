import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huinong_web/api/user_api.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/provider/app_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String _normalizePhone(String? value) {
    return (value ?? '').replaceAll(RegExp(r'\s|-'), '');
  }
  String? _validateUsername(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '请输入用户名';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,50}$').hasMatch(trimmed)) {
      return '用户名只能包含字母、数字和下划线，长度3-50位';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    final trimmed = value.trim();
    if (trimmed.length < 8 || trimmed.length > 20) {
      return '请设置 8-20 位密码（建议包含字母+数字）';
    }
    return null;
  }

    String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // 手机号为空时验证通过（因为是选填）
    }
    final normalized = _normalizePhone(value);
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(normalized)) {
      return '请输入有效的 11 位手机号';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final isElderMode = Provider.of<AppProvider>(context, listen: false).isElderlyMode;

    try {
      final user = await UserApi.instance.register(
        _usernameController.text,
        _passwordController.text,
        phone: _phoneController.text,
      );

      if (mounted) {
        final username = user.username;
        showDialog(
          context: context,
          builder: (dialogContext) {
            // 2秒后自动关闭弹窗
            Future.delayed(const Duration(seconds: 2), () {
              if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
            });
            return AlertDialog(
              title: Text('注册成功', style: TextStyle(fontSize: isElderMode ? 22 : 18, fontWeight: FontWeight.bold)),
              content: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: isElderMode ? 20 : 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: '注册成功！您的账号 '),
                    TextSpan(
                      text: username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isElderMode ? 22 : 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const TextSpan(text: ' 已创建，即将跳转到登录页'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('确定', style: TextStyle(fontSize: isElderMode ? 19 : 16)),
                ),
              ],
            );
          },
        ).then((_) {
          // 弹窗关闭后回到登录页，_AppShell 自然显示 LoginPage
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('注册失败', style: TextStyle(fontSize: isElderMode ? 22 : 18, fontWeight: FontWeight.bold)),
            content: Text(e.toString(), style: TextStyle(fontSize: isElderMode ? 20 : 16)),
            actions: [
              SizedBox(
                height: isElderMode ? 50 : 40,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('确定', style: TextStyle(fontSize: isElderMode ? 19 : 16)),
                ),
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    final isElderMode = Provider.of<AppProvider>(context).isElderlyMode;

    // Conditional Styling
    final double inputFontSize = isElderMode ? 18.0 : 14.0;
    final double buttonFontSize = isElderMode ? 19.0 : 16.0;
    final double agreementFontSize = isElderMode ? 16.0 : 12.0;
    final double elementSpacing = isElderMode ? 24.0 : 16.0;
    final double buttonHeight = isElderMode ? 56.0 : 44.0;
    final BorderRadius borderRadius = BorderRadius.circular(isElderMode ? 12.0 : 8.0);
    final Color inputTextColor = isElderMode ? const Color(0xFF333333) : Colors.black;
    final Color inputFillColor = isElderMode ? const Color(0xFFF5F5DC) : Colors.grey[200]!;
    final EdgeInsets inputPadding = EdgeInsets.symmetric(vertical: isElderMode ? 18 : 12, horizontal: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text('注册', style: TextStyle(fontSize: isElderMode ? 22 : 18)),
        actions: [
          Switch(
            value: isElderMode,
            onChanged: (value) {
              Provider.of<AppProvider>(context, listen: false).toggleElderlyMode();
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
                  validator: _validateUsername,
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
                    suffixIcon: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
                      child: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: _validatePassword,
                ),
                SizedBox(height: elementSpacing),
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(fontSize: inputFontSize, color: inputTextColor),
                  decoration: InputDecoration(
                    labelText: '手机号（选填）',
                    labelStyle: TextStyle(fontSize: inputFontSize, color: inputTextColor.withAlpha(179)),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide.none),
                    contentPadding: inputPadding,
                  ),
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: elementSpacing * 1.5),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: borderRadius),
                          ),
                          child: Text('注册', style: TextStyle(fontSize: buttonFontSize)),
                        ),
                      ),
                SizedBox(height: elementSpacing),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('已有账号？立即登录', style: TextStyle(fontSize: agreementFontSize)),
                ),
                SizedBox(height: elementSpacing),
                Text(
                  '点击注册即表示同意《慧农平台用户协议》',
                  style: TextStyle(color: Colors.grey, fontSize: agreementFontSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

