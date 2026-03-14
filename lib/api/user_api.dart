
import 'package:huinong_web/models/user_model.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:shared_preferences/shared_preferences.dart';

/// 用户 API 服务
class UserApi {
  UserApi._(); // 私有构造函数
  static final UserApi _instance = UserApi._();
  static UserApi get instance => _instance;

  /// 模拟获取当前登录用户信息
  Future<User?> getCurrentUser() async {
    debugPrint('模拟获取当前用户');
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    return User(
      id: 1,
      username: '测试用户',
      password: '******',
      phone: '13800138000',
      elderMode: false,
      createTime: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  /// 模拟用户退出登录
  Future<void> logout() async {
    debugPrint('模拟用户退出登录');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_id');
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟异步操作
  }

  // TODO: 可以根据后端接口继续添加更新用户信息、修改密码等方法
}
