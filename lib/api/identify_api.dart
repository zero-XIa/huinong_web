import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/models/identification_model.dart';

/// 病害识别相关接口
class IdentifyApi {
  IdentifyApi._();
  static final IdentifyApi _instance = IdentifyApi._();
  static IdentifyApi get instance => _instance;

  /// 上传图片进行病害识别
  ///
  /// 图片先存本地再上传 Dify 识别工作流，后端同步处理后返回结果
  Future<Identification> identify(
    XFile imageFile, {
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
      });

      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/crops/identify',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );

      return Identification.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('识别失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('识别时发生未知错误: $e');
      rethrow;
    }
  }

  /// 获取识别历史列表（分页）
  Future<Map<String, dynamic>> getHistory({
    int skip = 0,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await DioClient.instance.get<Map<String, dynamic>>(
        '/crops/history',
        queryParameters: {'skip': skip, 'limit': limit},
        cancelToken: cancelToken,
      );
      return response;
    } on ApiException catch (e) {
      debugPrint('获取识别历史失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取识别历史时发生未知错误: $e');
      rethrow;
    }
  }

  /// 获取单条识别记录详情
  Future<Identification> getHistoryDetail(
    int id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await DioClient.instance.get<Map<String, dynamic>>(
        '/crops/history/$id',
        cancelToken: cancelToken,
      );
      return Identification.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('获取识别记录详情失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取识别记录详情时发生未知错误: $e');
      rethrow;
    }
  }

  /// 删除单条识别记录
  Future<void> deleteHistory(int id) async {
    try {
      await DioClient.instance.delete<void>(
        '/crops/history/$id',
      );
    } on ApiException catch (e) {
      debugPrint('删除识别记录失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('删除识别记录时发生未知错误: $e');
      rethrow;
    }
  }
}
