import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/news_api.dart';
import 'package:huinong_web/models/news_model.dart';
import 'package:huinong_web/provider/app_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final List<News> _newsList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadMoreNews();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
        _loadMoreNews();
      }
    });
  }

  Future<void> _loadMoreNews() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final newNews = await NewsApi.instance.getNews(skip: _page * 10, limit: 10);
      if (newNews.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        setState(() {
          _newsList.addAll(newNews);
          _page++;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('资讯'),
        actions: [
          Switch(
            value: isElderMode,
            onChanged: (value) {
              appProvider.toggleElderlyMode();
            },
          ),
        ],
      ),
      body: MasonryGridView.count(
        controller: _scrollController,
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemCount: _newsList.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _newsList.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final news = _newsList[index];
          return _buildNewsCard(news, isElderMode);
        },
      ),
    );
  }

  Widget _buildNewsCard(News news, bool isElderMode) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.coverUrl != null && news.coverUrl!.isNotEmpty)
            Image.network(
              news.coverUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 120, // Adjust height as needed
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      child: Icon(Icons.admin_panel_settings, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '管理员',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isElderMode ? 16 : 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  news.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isElderMode ? 20 : 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (news.category != null)
                  Chip(
                    label: Text(news.category!),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
