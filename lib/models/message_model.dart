
import 'package:intl/intl.dart';

/// 消息模型 (Message Model)
///
/// 此模型与 FastAPI 后端 `crop.py` 中定义的 `Message` 数据结构完全对齐。
/// 主要用于聊天或问诊模块的消息记录。
///
/// **如何与 Dio 响应解析联动：**
/// 当使用 Dio 发送请求并收到响应后，可以通过以下方式将 JSON 数据转换为 Message 对象列表：
/// ```dart
/// final response = await DioClient.instance.get('/chat/history');
/// if (response.statusCode == 200) {
///   final List<Message> messages = (response.data as List)
///       .map((e) => Message.fromJson(e as Map<String, dynamic>))
///       .toList();
///   // 现在你可以使用 messages 列表了
/// }
/// ```
class Message {
  /// 消息ID
  /// 对应后端字段: `id` (Integer, primary_key)
  final int? id;

  /// 用户ID
  /// 对应后端字段: `user_id` (Integer, ForeignKey)
  final int? userId;

  /// 会话ID
  /// 对应后端字段: `session_id` (String, nullable=False)
  final String sessionId;

  /// 角色 (user 或 ai)
  /// 对应后端字段: `role` (String, nullable=False)
  final String role;

  /// 消息内容
  /// 对应后端字段: `content` (Text, nullable=False)
  final String content;

  /// 创建时间
  /// 对应后端字段: `create_time` (DateTime, server_default=func.now())
  final DateTime? createTime;

  Message({
    this.id,
    this.userId,
    required this.sessionId,
    required this.role,
    required this.content,
    this.createTime,
  });

  /// 从 JSON 数据创建 Message 对象的工厂构造函数。
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      sessionId: json['session_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createTime: json['create_time'] != null
          ? DateTime.parse(json['create_time'] as String)
          : null,
    );
  }

  /// 将 Message 对象转换为 JSON 格式的方法。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'create_time': createTime?.toIso8601String(),
    };
  }

  /// 示例：格式化创建时间
  /// 这是一个“特殊处理”方法，用于将 createTime 格式化为可读的字符串。
  String get formattedCreateTime {
    if (createTime == null) {
      return '未知时间';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(createTime!);
  }

  @override
  String toString() {
    return 'Message(id: $id, userId: $userId, sessionId: $sessionId, role: $role, content: $content, createTime: $createTime)';
  }
}
