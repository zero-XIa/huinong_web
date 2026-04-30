
import 'package:flutter/foundation.dart'; 
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/models/news_model.dart';
import 'package:huinong_web/models/common/paginated_response.dart';

/// 新闻 API 服务
class NewsApi {
  NewsApi._(); // 私有构造函数
  static final NewsApi _instance = NewsApi._();
  static NewsApi get instance => _instance;

  /// 分页获取资讯列表
  ///
  /// [skip] 跳过的记录数
  /// [limit] 每页获取条数
  Future<PaginatedResponse<News>> getNews({int skip = 0, int limit = 10}) async {
    try {
      final response = await DioClient.instance.get<Map<String, dynamic>>(
        '/news/',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      return PaginatedResponse.fromJson(response, (json) => News.fromJson(json));
    } on ApiException catch (e) {
      debugPrint('获取资讯列表失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取资讯列表时发生未知错误: $e');
      rethrow;
    }
  }

  /// 获取资讯详情
  ///
  /// [id] 资讯 ID
  Future<News> getNewsDetail(int id) async {
    try {
      final response = await DioClient.instance.get<Map<String, dynamic>>(
        '/news/$id/',
      );
      return News.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('获取资讯详情失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('获取资讯详情时发生未知错误: $e');
      rethrow;
    }
  }
}
