import 'package:intl/intl.dart';

class ChatSession {
  final String sessionId;
  final String title;
  final DateTime lastMessageTime;

  ChatSession({
    required this.sessionId,
    required this.title,
    required this.lastMessageTime,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'] as String,
      title: json['title'] as String? ?? '',
      lastMessageTime: DateTime.parse(json['last_message_time'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'title': title,
      'last_message_time': lastMessageTime.toIso8601String(),
    };
  }

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(lastMessageTime);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return DateFormat('MM-dd').format(lastMessageTime);
    }
  }

  @override
  String toString() {
    return 'ChatSession(sessionId: $sessionId, title: $title, lastMessageTime: $lastMessageTime)';
  }
}