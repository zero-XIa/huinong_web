import 'package:flutter/material.dart';
import 'package:huinong_web/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局应用状态管理
class AppProvider with ChangeNotifier {
  bool _isElderlyMode = false;
  User? _currentUser;

  bool get isElderlyMode => _isElderlyMode;
  User? get currentUser => _currentUser;

  AppProvider() {
    loadElderlyMode();
    loadUser();
  }

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

  // 设置用户
  Future<void> setUser(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    if (user.id != null) {
      await prefs.setInt('user_id', user.id!);
      await prefs.setString('username', user.username);
    }
    notifyListeners();
  }

  // 从本地存储加载用户
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final username = prefs.getString('username');

    if (userId != null && username != null) {
      _currentUser = User(id: userId, username: username);
      notifyListeners();
    }
  }

  // 退出登录
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    await resetElderlyMode();
    notifyListeners();
  }
}
