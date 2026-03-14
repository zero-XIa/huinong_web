import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局应用状态管理
class AppProvider with ChangeNotifier {
  bool _isElderlyMode = false; // 默认不是适老化模式

  bool get isElderlyMode => _isElderlyMode;

  // 加载适老化模式设置
  Future<void> loadElderlyMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isElderlyMode = prefs.getBool('isElderlyMode') ?? false;
    notifyListeners();
  }

  // 切换适老化模式
  Future<void> toggleElderlyMode() async {
    _isElderlyMode = !_isElderlyMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isElderlyMode', _isElderlyMode);
    notifyListeners(); // 通知所有监听者更新 UI
  }

  // 重置适老化模式 (例如，用户退出登录时)
  Future<void> resetElderlyMode() async {
    _isElderlyMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isElderlyMode');
    notifyListeners();
  }
}
