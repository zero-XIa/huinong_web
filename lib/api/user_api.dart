
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:dio/dio.dart'; // For Options
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/models/user_model.dart';

/// 用户 API 服务
class UserApi {
  UserApi._(); // 私有构造函数
  static final UserApi _instance = UserApi._();
  static UserApi get instance => _instance;

  /// 用户登录
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/users/login',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json', // 明确设置为JSON格式
          },
        ),
      );
      return response;
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
      if (phone != null && phone.trim().isNotEmpty) {
        data['phone'] = phone.trim().replaceAll(RegExp(r'\s|-'), '');
      }

      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/users/register',
        data: data,
      );

      return User.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('注册失败：${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('注册时发生未知错误：$e');
      rethrow;
    }
  }

  /// 获取当前用户信息
  Future<User> getCurrentUser() async {
    try {
      final response = await DioClient.instance.get<Map<String, dynamic>>(
        '/users/me',
      );
      return User.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('获取用户信息失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取用户信息时发生未知错误: $e');
      rethrow;
    }
  }

  /// 更新用户信息
  Future<User> updateUser({String? phone, bool? elderMode}) async {
    try {
      final data = <String, dynamic>{};
      if (phone != null) {
        data['phone'] = phone;
      }
      if (elderMode != null) {
        data['elder_mode'] = elderMode;
      }

      debugPrint('[API] 发送 PUT /users/me, 请求体: $data');
      final response = await DioClient.instance.put<Map<String, dynamic>>(
        '/users/me',
        data: data,
      );
      if (response == null) {
        throw Exception('更新用户信息失败：响应为空');
      }
      final user = User.fromJson(response);
      debugPrint('[API] PUT 响应成功, 返回用户 elder_mode: ${user.elderMode}');
      return user;
    } on ApiException catch (e) {
      debugPrint('[API] 更新用户信息失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[API] 更新用户信息时发生未知错误: $e');
      rethrow;
    }
  }

  /// 修改密码
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final data = <String, dynamic>{
        'old_password': oldPassword,
        'new_password': newPassword,
      };
      debugPrint('[API] 发送 PUT /users/password, 请求体: $data');
      await DioClient.instance.put<Map<String, dynamic>>(
        '/users/password',
        data: data,
      );
      debugPrint('[API] 修改密码成功');
    } on ApiException catch (e) {
      debugPrint('[API] 修改密码失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[API] 修改密码时发生未知错误: $e');
      rethrow;
    }
  }
}
