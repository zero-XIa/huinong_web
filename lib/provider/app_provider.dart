import 'package:flutter/material.dart';
import 'package:huinong_web/api/user_api.dart';
import 'package:huinong_web/main.dart';
import 'package:huinong_web/models/user_model.dart';
import 'package:huinong_web/utils/secure_storage.dart';

/// 全局应用状态管理
class AppProvider with ChangeNotifier {
  bool _isElderlyMode = false;
  User? _currentUser;
  String? _accessToken;
  bool _isLoggingOut = false;

  bool get isElderlyMode => _isElderlyMode;
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _currentUser != null && _accessToken != null;
  bool get isLoggingOut => _isLoggingOut;

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

  // 更新长辈模式（仅本地，不同步后端，避免频繁写库）
  Future<void> updateElderMode(bool value, BuildContext context) async {
    if (_isElderlyMode == value) return;
    _isElderlyMode = value;
    await SecureStorage.instance.saveElderMode(value);
    notifyListeners();
  }

  // 将当前长辈模式单向同步到服务端
  // 仅在登录(setUser)和登出(logout)时调用，避免频繁写库
  Future<void> _syncElderModeToServer() async {
    if (_currentUser == null || _accessToken == null) {
      debugPrint('[APP] _syncElderModeToServer: 未登录，跳过同步');
      return;
    }
    debugPrint('[APP] 开始同步长辈模式到服务端, elderMode: $_isElderlyMode, token: ${_accessToken!.substring(0, 10)}...');
    try {
      final updatedUser = await UserApi.instance.updateUser(elderMode: _isElderlyMode);
      _currentUser = updatedUser;
      debugPrint('[APP] 长辈模式同步成功, 服务端返回 elderMode: ${updatedUser.elderMode}');
    } catch (e) {
      debugPrint('[APP] 同步长辈模式到服务端失败: $e');
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
    debugPrint('[APP] setUser 被调用, 服务端 elderMode: ${user.elderMode}, token 已获取');
    
    _currentUser = user;
    _accessToken = token;
    
    await SecureStorage.instance.saveToken(token);
    if (user.id != null) {
      await SecureStorage.instance.saveUserId(user.id!);
      await SecureStorage.instance.saveUsername(user.username);
    }
    
    // 登录时合并本地与服务端的长辈模式值：
    // 用户登录页的选择（本地）优先，服务端历史值兜底恢复，使用 OR 确保不丢失任一方的 true
    final localElderMode = _isElderlyMode;
    _isElderlyMode = _isElderlyMode || user.elderMode;
    await SecureStorage.instance.saveElderMode(_isElderlyMode);
    debugPrint('[APP] 登录时 elderMode 合并: 本地=$localElderMode, 服务端=${user.elderMode}, 结果=$_isElderlyMode');

    // 如果本地值与服务端不一致，将用户选择同步到服务端
    if (_isElderlyMode != user.elderMode) {
      debugPrint('[APP] 本地与服务端 elderMode 不一致，同步到服务端');
      _syncElderModeToServer();
    }

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
      debugPrint('[APP] checkLoginStatus 获取用户, 服务端 elderMode: ${user.elderMode}');
      
      _currentUser = user;
      _accessToken = token;
      // 保持本地 SecureStorage 的长辈模式值，不覆盖
      debugPrint('[APP] checkLoginStatus 保持本地 elderMode = $_isElderlyMode');
      
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
    _isLoggingOut = true;
    // 登出前将当前长辈模式同步到服务端
    await _syncElderModeToServer();
    
    _currentUser = null;
    _accessToken = null;
    
    await SecureStorage.instance.clearAll();
    await resetElderlyMode();
    
    // _AppShell 已通过 notifyListeners() 重建并显示 LoginPage，仅需 pop 回到根路由
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.popUntil((route) => route.isFirst);
    }
    
    notifyListeners();
  }
}
