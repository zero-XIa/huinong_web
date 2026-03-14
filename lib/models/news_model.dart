
import 'package:intl/intl.dart';

/// 新闻模型 (News Model)
///
/// 此模型与 FastAPI 后端 `news.py` 中定义的 `News` 数据结构完全对齐。
/// 用于展示政策、预警、农技等各类新闻资讯。
///
/// **如何与 Dio 响应解析联动：**
/// 当使用 Dio 发送请求并收到响应后，可以通过以下方式将 JSON 数据转换为 News 对象列表：
/// ```dart
/// final response = await DioService.instance.get('/news');
/// if (response.statusCode == 200) {
///   final List<News> newsList = (response.data as List)
///       .map((e) => News.fromJson(e as Map<String, dynamic>))
///       .toList();
///   // 现在你可以使用 newsList 了
/// }
/// ```
class News {
  /// 新闻ID
  /// 对应后端字段: `id` (Integer, primary_key)
  final int? id;

  /// 标题
  /// 对应后端字段: `title` (String, nullable=False)
  final String title;

  /// 内容 (可能包含 Markdown 或 HTML)
  /// 对应后端字段: `content` (Text, nullable=False)
  final String content;

  /// 分类 (如：政策、预警、农技)
  /// 对应后端字段: `category` (String, nullable=True)
  final String? category;

  /// 封面图片URL
  /// 对应后端字段: `cover_url` (String, nullable=True)
  final String? coverUrl;

  /// 发布时间
  /// 对应后端字段: `publish_time` (DateTime, default=datetime.now)
  final DateTime? publishTime;

  /// 浏览次数
  /// 对应后端字段: `view_count` (Integer, default=0)
  final int? viewCount;

  News({
    this.id,
    required this.title,
    required this.content,
    this.category,
    this.coverUrl,
    this.publishTime,
    this.viewCount = 0,
  });

  /// 从 JSON 数据创建 News 对象的工厂构造函数。
  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as int?,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String?,
      coverUrl: json['cover_url'] as String?,
      publishTime: json['publish_time'] != null
          ? DateTime.parse(json['publish_time'] as String)
          : null,
      viewCount: json['view_count'] as int? ?? 0,
    );
  }

  /// 将 News 对象转换为 JSON 格式的方法。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'cover_url': coverUrl,
      'publish_time': publishTime?.toIso8601String(),
      'view_count': viewCount,
    };
  }

  /// 示例：格式化发布时间
  /// 这是一个方法，用于将 publishTime 格式化为可读的字符串。
  String get formattedPublishTime {
    if (publishTime == null) {
      return '未知时间';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(publishTime!);
  }

  @override
  String toString() {
    return 'News(id: $id, title: $title, category: $category, publishTime: $publishTime, viewCount: $viewCount)';
  }
}
