
import 'package:flutter/foundation.dart'; 
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/models/news_model.dart';

/// 新闻 API 服务
class NewsApi {
  NewsApi._(); // 私有构造函数
  static final NewsApi _instance = NewsApi._();
  static NewsApi get instance => _instance;

  /// 分页获取资讯列表
  ///
  /// [skip] 跳过的记录数
  /// [limit] 每页获取条数
  Future<List<News>> getNews({int skip = 0, int limit = 10}) async {
    try {
      final response = await DioClient.instance.get<List<dynamic>>(
        '/news/',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      return response.map((json) => News.fromJson(json)).toList();
    } on ApiException catch (e) {
      debugPrint('获取资讯列表失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取资讯列表时发生未知错误: $e');
      rethrow;
    }
  }
}
