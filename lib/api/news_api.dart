
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
        '/news',
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
        '/news/$id',
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

  /// 管理员 - 创建资讯
  Future<News> createNews({
    required String title,
    required String content,
    String? category,
    String? coverUrl,
  }) async {
    try {
      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/news',
        data: {
          'title': title,
          'content': content,
          'publish_time': DateTime.now().toIso8601String(),
          if (category != null && category.isNotEmpty) 'category': category,
          if (coverUrl != null && coverUrl.isNotEmpty) 'cover_url': coverUrl,
        },
      );
      return News.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('创建资讯失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('创建资讯时发生未知错误: $e');
      rethrow;
    }
  }

  /// 管理员 - 更新资讯
  Future<News> updateNews(int id, {
    String? title,
    String? content,
    String? category,
    String? coverUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (category != null) data['category'] = category;
      if (coverUrl != null) data['cover_url'] = coverUrl;

      final response = await DioClient.instance.put<Map<String, dynamic>>(
        '/news/$id',
        data: data,
      );
      if (response == null) {
        throw ApiException('更新资讯失败：响应为空');
      }
      return News.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('更新资讯失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('更新资讯时发生未知错误: $e');
      rethrow;
    }
  }

  /// 管理员 - 删除资讯
  Future<void> deleteNews(int id) async {
    try {
      await DioClient.instance.delete<void>('/news/$id');
    } on ApiException catch (e) {
      debugPrint('删除资讯失败: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('删除资讯时发生未知错误: $e');
      rethrow;
    }
  }
}
