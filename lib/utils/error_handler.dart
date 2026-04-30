import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:huinong_web/api/dio_client.dart';

class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is ApiException) {
      return _mapErrorCodeToMessage(error.code, error.message);
    }
    if (error is Exception) {
      return error.toString();
    }
    return '网络错误，请检查连接';
  }

  static String _mapErrorCodeToMessage(int? code, String? message) {
    switch (code) {
      case 40101:
        return '登录已过期，请重新登录';
      case 40301:
        return '权限不足';
      case 40001:
        return message != null && message.isNotEmpty
            ? '输入信息有误：$message'
            : '输入信息有误';
      case 40401:
        return '内容不存在，请刷新';
      case 50003:
        return 'AI服务异常，请稍后重试';
      default:
        return message ?? '网络错误，请检查连接';
    }
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getUserFriendlyMessage(error);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static void logError(String tag, dynamic error) {
    if (kDebugMode) {
      debugPrint('[$tag] Error: $error');
    }
  }
}