import 'package:flutter/material.dart';
import 'package:huinong_web/api/user_api.dart';
import 'package:huinong_web/main.dart'; // 导入全局导航键
import 'package:huinong_web/models/user_model.dart';
import 'package:huinong_web/pages/login/login_page.dart'; // 导入 LoginPage
import 'package:huinong_web/utils/error_handler.dart';
import 'package:huinong_web/utils/secure_storage.dart';

/// 全局应用状态管理
class AppProvider with ChangeNotifier {
  bool _isElderlyMode = false;
  User? _currentUser;
  String? _accessToken;

  bool get isElderlyMode => _isElderlyMode;
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _currentUser != null && _accessToken != null;

  AppProvider() {
    loadElderlyMode();
  }

  // 加载长辈模式设置
  Future<void> loadElderlyMode() async {
    _isElderlyMode = await SecureStorage.instance.getElderMode();
    notifyListeners();
  }

  // 切换长辈模式
  Future<void> toggleElderlyMode() async {
    _isElderlyMode = !_isElderlyMode;
    await SecureStorage.instance.saveElderMode(_isElderlyMode);
    notifyListeners(); // 通知所有监听者更新 UI
  }

  // 更新长辈模式（同步后端）
  Future<void> updateElderMode(bool value, BuildContext context) async {
    final oldValue = _isElderlyMode;
    debugPrint('[APP] updateElderMode 被调用, oldValue: $oldValue, newValue: $value');
    
    // 乐观更新
    debugPrint('[APP] 乐观更新前 _isElderlyMode = $_isElderlyMode');
    _isElderlyMode = value;
    debugPrint('[APP] 乐观更新后 _isElderlyMode = $_isElderlyMode');
    debugPrint('[APP] 准备调用 notifyListeners() (乐观更新)');
    notifyListeners();

    try {
      debugPrint('[APP] 准备调用 UserApi.updateUser(elderMode: $value)');
      final updatedUser = await UserApi.instance.updateUser(elderMode: value);
      debugPrint('[APP] API 调用成功, 返回 elderMode: ${updatedUser.elderMode}');
      _currentUser = updatedUser;
      await SecureStorage.instance.saveElderMode(value);
      debugPrint('[APP] 准备调用 notifyListeners() (成功)');
      notifyListeners();
      debugPrint('[APP] updateElderMode 成功完成');
    } catch (e) {
      debugPrint('[APP] API 调用失败: $e');
      debugPrint('[APP] 回滚 _isElderlyMode 从 $value 到 $oldValue');
      _isElderlyMode = oldValue;
      debugPrint('[APP] 准备调用 notifyListeners() (回滚)');
      notifyListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ScaffoldMessenger.maybeOf(context) != null) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      });
    }
  }

  // 更新用户信息
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // 重置长辈模式 (例如，用户退出登录时)
  Future<void> resetElderlyMode() async {
    _isElderlyMode = false;
    await SecureStorage.instance.saveElderMode(false);
    notifyListeners();
  }

  // 设置用户和 token
  Future<void> setUser(User user, String token) async {
    debugPrint('[APP] setUser 被调用, elderMode: ${user.elderMode}, token 已获取');
    
    _currentUser = user;
    _accessToken = token;
    
    await SecureStorage.instance.saveToken(token);
    if (user.id != null) {
      await SecureStorage.instance.saveUserId(user.id!);
      await SecureStorage.instance.saveUsername(user.username);
    }
    
    debugPrint('[APP] 更新前 _isElderlyMode = $_isElderlyMode');
    await SecureStorage.instance.saveElderMode(user.elderMode);
    _isElderlyMode = user.elderMode;
    debugPrint('[APP] 更新后 _isElderlyMode = $_isElderlyMode');
    
    debugPrint('[APP] 准备调用 notifyListeners()');
    notifyListeners();
    debugPrint('[APP] setUser 完成');
  }

  // 检查登录状态
  Future<bool> checkLoginStatus() async {
    final token = await SecureStorage.instance.getToken();
    if (token == null) {
      debugPrint('[APP] checkLoginStatus: token 为空，返回 false');
      return false;
    }
    
    try {
      debugPrint('[APP] checkLoginStatus: 准备调用 getCurrentUser()');
      final user = await UserApi.instance.getCurrentUser();
      debugPrint('[APP] checkLoginStatus 获取用户, elderMode: ${user.elderMode}');
      
      _currentUser = user;
      _accessToken = token;
      debugPrint('[APP] 更新前 _isElderlyMode = $_isElderlyMode');
      _isElderlyMode = user.elderMode;
      debugPrint('[APP] 更新后 _isElderlyMode = $_isElderlyMode');
      
      debugPrint('[APP] 准备调用 notifyListeners()');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[APP] checkLoginStatus 失败: $e');
      await SecureStorage.instance.deleteToken();
      _accessToken = null;
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  // 退出登录
  Future<void> logout() async {
    _currentUser = null;
    _accessToken = null;
    
    // 清除安全存储中的数据
    await SecureStorage.instance.clearAll();
    await resetElderlyMode();
    
    // 先跳转登录页，再通知监听者
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
    
    notifyListeners();
  }
}
