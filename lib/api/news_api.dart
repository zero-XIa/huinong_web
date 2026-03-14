
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/models/news_model.dart';

/// 新闻 API 服务
class NewsApi {
  NewsApi._(); // 私有构造函数
  static final NewsApi _instance = NewsApi._();
  static NewsApi get instance => _instance;

  /// 获取新闻列表
  Future<List<News>> getNewsList() async {
    try {
      final response = await DioClient.instance.get<List<dynamic>>(
        '/news/list',
      );
      return response.map((json) => News.fromJson(json)).toList();
    } on ApiException catch (e) {
      debugPrint('获取新闻列表失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取新闻列表发生未知错误: $e');
      rethrow;
    }
  }
}
