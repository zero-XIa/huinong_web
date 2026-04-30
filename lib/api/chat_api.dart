import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:huinong_web/api/dio_client.dart';

class ChatApi {
  ChatApi._();
  static final ChatApi _instance = ChatApi._();
  static ChatApi get instance => _instance;

  Future<Map<String, dynamic>> sendTextMessage(
    String content, {
    String? sessionId,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'content': content,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      });

      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/chat/message',
        data: formData,
        cancelToken: cancelToken,
      );

      return response;
    } on ApiException catch (e) {
      debugPrint('发送文本消息失败：${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('发送文本消息时发生未知错误：$e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendImageMessage(
    XFile imageFile, {
    String? text,
    String? sessionId,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
        if (text != null && text.isNotEmpty) 'text': text,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      });

      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/chat/message_with_image',
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );

      return response;
    } on ApiException catch (e) {
      debugPrint('发送图片消息失败：${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('发送图片消息时发生未知错误：$e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSessions({
    int skip = 0,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await DioClient.instance.get<Map<String, dynamic>>(
        '/chat/sessions',
        queryParameters: {'skip': skip, 'limit': limit},
        cancelToken: cancelToken,
      );
      return response;
    } on ApiException catch (e) {
      debugPrint('获取会话列表失败：${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取会话列表时发生未知错误：$e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMessages(
    String sessionId, {
    int skip = 0,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await DioClient.instance.get<Map<String, dynamic>>(
        '/chat/sessions/$sessionId/messages',
        queryParameters: {'skip': skip, 'limit': limit},
        cancelToken: cancelToken,
      );
      return response;
    } on ApiException catch (e) {
      debugPrint('获取会话消息失败：${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取会话消息时发生未知错误：$e');
      rethrow;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await DioClient.instance.delete<void>(
        '/chat/sessions/$sessionId',
      );
    } on ApiException catch (e) {
      debugPrint('删除会话失败：${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('删除会话时发生未知错误：$e');
      rethrow;
    }
  }
}