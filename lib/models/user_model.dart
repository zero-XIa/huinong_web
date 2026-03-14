
import 'package:intl/intl.dart';

/// 用户模型 (User Model)
///
/// 此模型与 FastAPI 后端的用户数据结构完全对齐。
/// 它支持从 JSON 反序列化 (`fromJson`) 和序列化为 JSON (`toJson`)。
///
/// **如何与 Dio 响应解析联动：**
/// 当使用 Dio 发送请求并收到响应后，可以通过以下方式将 JSON 数据转换为 User 对象：
/// ```dart
/// final response = await DioClient.instance.get('/users/me');
/// if (response.statusCode == 200) {
///   final User user = User.fromJson(response.data);
///   // 现在你可以使用 user 对象了
/// }
/// ```
class User {
  /// 用户ID
  /// 对应后端字段: `id` (Integer, primary_key)
  final int? id;

  /// 用户名
  /// 对应后端字段: `username` (String, unique, nullable=False)
  final String username;

  /// 密码 (通常不在前端直接传输或显示，此处仅为模型对齐)
  /// 对应后端字段: `password` (String, nullable=False)
  final String password;

  /// 手机号码
  /// 对应后端字段: `phone` (String, unique, nullable=True)
  final String? phone;

  /// 适老化模式标记
  /// 对应后端字段: `elder_mode` (Boolean, default=False)
  /// 用于判断是否启用适老化界面，这是您提到的“适老化标记字段”。
  final bool elderMode;

  /// 创建时间
  /// 对应后端字段: `create_time` (DateTime, server_default=func.now())
  final DateTime? createTime;

  User({
    this.id,
    required this.username,
    required this.password,
    this.phone,
    this.elderMode = false, // 默认值为 false
    this.createTime,
  });

  /// 从 JSON 数据创建 User 对象的工厂构造函数。
  ///
  /// 注意：后端返回的 `create_time` 可能是字符串，需要解析为 DateTime。
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String,
      password: json['password'] as String,
      phone: json['phone'] as String?,
      elderMode: json['elder_mode'] as bool? ?? false, // 后端默认值，前端也给个默认值
      createTime: json['create_time'] != null
          ? DateTime.parse(json['create_time'] as String)
          : null,
    );
  }

  /// 将 User 对象转换为 JSON 格式的方法。
  ///
  /// 注意：`createTime` 在转换为 JSON 时需要格式化为字符串。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'phone': phone,
      'elder_mode': elderMode,
      'create_time': createTime?.toIso8601String(), // 转换为 ISO 8601 字符串
    };
  }

  /// 示例：格式化创建时间
  /// 这是一个“特殊处理”方法，用于将 createTime 格式化为可读的字符串。
  String get formattedCreateTime {
    if (createTime == null) {
      return '未知时间';
    }
    // 使用 intl 包进行格式化，需要添加到 pubspec.yaml
    // dependencies:
    //   intl: ^0.18.1 (或最新版本)
    return DateFormat('yyyy-MM-dd HH:mm').format(createTime!);
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, phone: $phone, elderMode: $elderMode, createTime: $createTime)';
  }
}
