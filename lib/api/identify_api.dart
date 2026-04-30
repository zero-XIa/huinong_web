import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/models/identification_model.dart';

class IdentifyApi {
  IdentifyApi._();
  static final IdentifyApi _instance = IdentifyApi._();
  static IdentifyApi get instance => _instance;

  Future<Identification> identify(
    XFile imageFile, {
    String? cropName,
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
        if (cropName != null && cropName.isNotEmpty) 'crop_name': cropName,
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