import 'package:flutter/material.dart';
import 'package:huinong_web/pages/login/login_page.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/models/user_model.dart';
import 'package:huinong_web/provider/app_provider.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // 从 AppProvider 获取当前用户信息
    _currentUser = Provider.of<AppProvider>(context, listen: false).currentUser;
  }

  Future<void> _logout() async {
    // 通过 AppProvider 退出登录
    await Provider.of<AppProvider>(context, listen: false).logout();
    if (mounted) {
      // 导航到登录页
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildInfoRow(String label, String value, bool isElderMode, Color elderTextColor, double baseFontSize, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: padding / 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isElderMode ? baseFontSize : 16.0,
              fontWeight: FontWeight.bold,
              color: isElderMode ? elderTextColor : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isElderMode ? baseFontSize : 16.0,
              color: isElderMode ? elderTextColor : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;

    // 适老化样式配置
    final double baseFontSize = isElderMode ? 18.0 : 14.0;
    final double titleFontSize = isElderMode ? 22.0 : 16.0;
    final double buttonTextFontSize = isElderMode ? 20.0 : 16.0;
    final double padding = isElderMode ? 20.0 : 8.0;
    final double buttonHeight = isElderMode ? 50.0 : 40.0;
    const Color elderTextColor = Color(0xFF333333);
    const Color elderBackgroundColor = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: isElderMode ? elderBackgroundColor : null,
      appBar: AppBar(
        title: Text(
          '我的',
          style: TextStyle(
            fontSize: isElderMode ? titleFontSize : null,
            color: isElderMode ? elderTextColor : null,
          ),
        ),
      ),
      body: _currentUser == null
          ? const Center(child: Text('未能加载用户信息'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户信息卡片
                  Card(
                    elevation: isElderMode ? 4.0 : null,
                    margin: EdgeInsets.only(bottom: padding),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '个人信息',
                            style: TextStyle(
                              fontSize: isElderMode ? titleFontSize : 18.0,
                              fontWeight: FontWeight.bold,
                              color: isElderMode ? elderTextColor : Colors.black87,
                            ),
                          ),
                          SizedBox(height: padding),
                          _buildInfoRow('用户名', _currentUser!.username, isElderMode, elderTextColor, baseFontSize, padding),
                          _buildInfoRow('手机号', _currentUser!.phone ?? '未设置', isElderMode, elderTextColor, baseFontSize, padding),
                          _buildInfoRow('注册时间', _currentUser!.formattedCreateTime, isElderMode, elderTextColor, baseFontSize, padding),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: padding),
                  // 适老化模式开关
                  Card(
                    elevation: isElderMode ? 4.0 : null,
                    margin: EdgeInsets.only(bottom: padding),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '适老化模式',
                            style: TextStyle(
                              fontSize: isElderMode ? titleFontSize : 18.0,
                              fontWeight: FontWeight.bold,
                              color: isElderMode ? elderTextColor : Colors.black87,
                            ),
                          ),
                          Switch(
                            value: isElderMode,
                            onChanged: (value) {
                              appProvider.toggleElderlyMode();
                            },
                            activeTrackColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: padding * 2),
                  // 退出登录按钮
                  SizedBox(
                    height: buttonHeight,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: isElderMode
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              textStyle: TextStyle(fontSize: buttonTextFontSize),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            )
                          : ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                      child: Text(
                        '退出登录',
                        style: TextStyle(fontSize: isElderMode ? buttonTextFontSize : null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
