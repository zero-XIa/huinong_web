import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储工具类，用于存储敏感信息如 token
class SecureStorage {
  SecureStorage._();
  static final SecureStorage _instance = SecureStorage._();
  static SecureStorage get instance => _instance;
  
  final _storage = const FlutterSecureStorage();
  
  // 存储键常量
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _elderModeKey = 'elder_mode';
  
  /// 保存 token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }
  
  /// 获取 token
  Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  /// 删除 token
  Future<void> deleteToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
  
  /// 保存用户 ID
  Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
  }
  
  /// 获取用户 ID
  Future<int?> getUserId() async {
    final value = await _storage.read(key: _userIdKey);
    return value != null ? int.tryParse(value) : null;
  }
  
  /// 保存用户名
  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }
  
  /// 获取用户名
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }
  
  /// 保存长辈模式
  Future<void> saveElderMode(bool value) async {
    await _storage.write(key: _elderModeKey, value: value.toString());
  }
  
  /// 获取长辈模式
  Future<bool> getElderMode() async {
    final value = await _storage.read(key: _elderModeKey);
    return value == 'true';
  }
  
  /// 清空所有存储的数据
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}