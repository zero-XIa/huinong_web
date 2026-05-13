import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/widgets/center_toast.dart';

class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is ApiException) {
      return _mapErrorCodeToMessage(error.code, error.message);
    }
    if (error is String) {
      return error;
    }
    if (error is Exception) {
      return error.toString();
    }
    return '网络错误，请检查连接';
  }

  static String _mapErrorCodeToMessage(int? code, String? message) {
    final hasServerMsg = message != null && message.isNotEmpty;

    switch (code) {
      case 40001:
        return hasServerMsg ? message : '输入信息有误，请检查';
      case 40101:
        return hasServerMsg ? message : '登录已过期，请重新登录';
      case 40301:
        return hasServerMsg ? message : '无权限访问';
      case 40401:
        return hasServerMsg ? message : '内容不存在';
      case 40402:
        return hasServerMsg ? message : '用户不存在';
      case 40403:
        return hasServerMsg ? message : '资讯不存在';
      case 40404:
        return hasServerMsg ? message : '识别记录不存在';
      case 40901:
        return hasServerMsg ? message : '用户名已存在';
      case 50000:
        return hasServerMsg ? message : '服务器繁忙，请稍后重试';
      case 50002:
        return hasServerMsg ? message : '文件上传失败';
      case 50003:
        return hasServerMsg ? message : 'AI服务异常，请稍后重试';
      default:
        return hasServerMsg ? message : '网络错误，请检查连接';
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

  static void showCenterError(
    BuildContext context,
    dynamic error, {
    bool isElderMode = false,
  }) {
    final message = getUserFriendlyMessage(error);
    CenterToast.show(
      context,
      message,
      isError: true,
      isElderMode: isElderMode,
      duration: const Duration(seconds: 3),
    );
  }

  static void logError(String tag, dynamic error) {
    if (kDebugMode) {
      debugPrint('[$tag] Error: $error');
    }
  }
}
