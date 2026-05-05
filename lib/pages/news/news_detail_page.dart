import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/news_api.dart';
import 'package:huinong_web/models/news_model.dart';
import 'package:huinong_web/provider/app_provider.dart';

class NewsDetailPage extends StatefulWidget {
  final int id;

  const NewsDetailPage({super.key, required this.id});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late Future<News?> _newsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _newsFuture = _fetchNewsDetail();
  }

  Future<News?> _fetchNewsDetail() async {
    try {
      return await NewsApi.instance.getNewsDetail(widget.id);
    } catch (e) {
      debugPrint('获取资讯详情失败: $e');
      return null;
    }
  }

  void _handleRetry() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isElderMode = appProvider.isElderlyMode;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '资讯详情',
              style: TextStyle(
                fontSize: isElderMode ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: FutureBuilder<News?>(
            future: _newsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingIndicator();
              }

              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorView(onRetry: _handleRetry);
              }

              final news = snapshot.data!;
              return _buildContent(news, isElderMode);
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(News news, bool isElderMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news.title,
            style: TextStyle(
              fontSize: isElderMode ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                news.formattedPublishTime,
                style: TextStyle(
                  fontSize: isElderMode ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
              const Text(' · '),
              Text(
                '阅读 ${news.viewCount ?? 0}',
                style: TextStyle(
                  fontSize: isElderMode ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildContentSection(news.content, isElderMode),
        ],
      ),
    );
  }

  Widget _buildContentSection(String content, bool isElderMode) {
    if (content.isEmpty) {
      return const Center(
        child: Text(
          '暂无正文',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final ContentType type = _detectContentType(content);

    switch (type) {
      case ContentType.html:
        return _buildHtmlContent(content, isElderMode);
      case ContentType.markdown:
        return _buildMarkdownContent(content, isElderMode);
      default:
        return _buildPlainText(content, isElderMode);
    }
  }

  ContentType _detectContentType(String content) {
    final htmlPatterns = [r'<p\b', r'<div\b', r'<img\b', r'<br\b', r'<h[1-6]\b'];
    for (final pattern in htmlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(content)) {
        return ContentType.html;
      }
    }

    final markdownPatterns = [
      r'^#{1,6}\s+',
      r'\*\*\w+\*\*',
      r'^\s*[-*+]\s+',
      r'^\s*>\s+',
      r'!\[.*?\]\(.*?\)',
      r'`[^`]+`',
      r'^\s*\d+\.\s+',
    ];
    for (final pattern in markdownPatterns) {
      if (RegExp(pattern, multiLine: true).hasMatch(content)) {
        return ContentType.markdown;
      }
    }

    return ContentType.plainText;
  }

  Widget _buildHtmlContent(String content, bool isElderMode) {
    return Html(
      data: content,
    );
  }

  Widget _buildMarkdownContent(String content, bool isElderMode) {
    final double baseFontSize = isElderMode ? 20 : 16;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: baseFontSize,
          height: 1.8,
          color: textColor,
        ),
        h1: TextStyle(
          fontSize: baseFontSize * 1.5,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h2: TextStyle(
          fontSize: baseFontSize * 1.4,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h3: TextStyle(
          fontSize: baseFontSize * 1.3,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h4: TextStyle(
          fontSize: baseFontSize * 1.2,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h5: TextStyle(
          fontSize: baseFontSize * 1.1,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h6: TextStyle(
          fontSize: baseFontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        code: TextStyle(
          fontSize: baseFontSize * 0.9,
          fontFamily: 'monospace',
          color: Colors.grey[800],
        ),
        listBullet: TextStyle(
          fontSize: baseFontSize,
          color: textColor,
          height: 1.8,
        ),
        blockquote: TextStyle(
          fontSize: baseFontSize,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildPlainText(String content, bool isElderMode) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return SelectableText(
      content,
      style: TextStyle(
        fontSize: isElderMode ? 20 : 16,
        height: 1.8,
        color: textColor,
      ),
    );
  }
}

enum ContentType {
  html,
  markdown,
  plainText,
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isElderMode = Provider.of<AppProvider>(context).isElderlyMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败，请重试',
            style: TextStyle(
              fontSize: isElderMode ? 20 : 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(
              '重试',
              style: TextStyle(
                fontSize: isElderMode ? 18 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}