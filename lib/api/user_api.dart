
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/models/user_model.dart';

/// 用户 API 服务
class UserApi {
  UserApi._(); // 私有构造函数
  static final UserApi _instance = UserApi._();
  static UserApi get instance => _instance;

  /// 用户登录
  Future<User> login(String username, String password) async {
    try {
      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/users/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      return User.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('登录失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('登录时发生未知错误: $e');
      rethrow;
    }
  }

  /// 用户注册
  Future<User> register(String username, String password, {String? phone}) async {
    try {
      final data = {
        'username': username,
        'password': password,
      };
      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
      }

      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/users/register',
        data: data,
      );

      return User.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('注册失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('注册时发生未知错误: $e');
      rethrow;
    }
  }
}
