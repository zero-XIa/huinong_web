import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/models/identification_model.dart'; // Assuming this model exists

/// 问诊 API 服务
class ConsultApi {
  ConsultApi._();
  static final ConsultApi _instance = ConsultApi._();
  static ConsultApi get instance => _instance;

  /// 提交文本问诊 (模拟)
  Future<bool> submitTextConsultation(String content) async {
    debugPrint('模拟提交问诊内容: $content');
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    return true; // 模拟提交成功
  }

  /// 获取问诊历史 (作物识别历史)
  Future<List<Identification>> getConsultationHistory(int userId) async {
    try {
      // 假设后端有一个接口返回用户的所有作物识别记录作为问诊历史
      final response = await DioClient.instance.get<List<dynamic>>(
        '/crops/history/$userId',
      );
      return response.map((json) => Identification.fromJson(json)).toList();
    } on ApiException catch (e) {
      debugPrint('获取问诊历史失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取问诊历史发生未知错误: $e');
      rethrow;
    }
  }
}
