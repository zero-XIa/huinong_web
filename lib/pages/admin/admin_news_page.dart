import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/news_api.dart';
import 'package:huinong_web/models/news_model.dart';
import 'package:huinong_web/provider/app_provider.dart';
import 'package:huinong_web/utils/error_handler.dart';

class AdminNewsPage extends StatefulWidget {
  const AdminNewsPage({super.key});

  @override
  State<AdminNewsPage> createState() => _AdminNewsPageState();
}

class _AdminNewsPageState extends State<AdminNewsPage> {
  final List<News> _newsList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  String? _selectedCategory;

  static const _categories = ['全部', '政策', '农技', '市场', '预警'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        _hasMore &&
        !_isLoading) {
      _loadNews();
    }
  }

  Future<void> _loadNews({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (reset) {
        _skip = 0;
        _newsList.clear();
        _hasMore = true;
      }
    });

    try {
      final response = await NewsApi.instance.getNews(skip: _skip, limit: 10);
      final newNews = response.list;
      if (newNews.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _newsList.addAll(newNews);
          _skip += newNews.length;
          _hasMore = _newsList.length < response.total;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadNews(reset: true);
  }

  void _showEditDialog({News? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    final coverCtrl = TextEditingController(text: existing?.coverUrl ?? '');
    String? selectedCat = existing?.category;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing != null ? '编辑资讯' : '新增资讯'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: '标题',
                        hintText: '请输入资讯标题',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: '正文',
                        hintText: '支持 Markdown / HTML / 纯文本',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      decoration: const InputDecoration(labelText: '分类'),
                      items: _categories
                          .where((c) => c != '全部')
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedCat = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: coverCtrl,
                      decoration: const InputDecoration(
                        labelText: '封面图 URL（可选）',
                        hintText: 'https://...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ErrorHandler.showErrorSnackBar(ctx, '标题不能为空');
                            return;
                          }
                          if (titleCtrl.text.trim().length > 200) {
                            ErrorHandler.showErrorSnackBar(ctx, '标题不能超过200个字符');
                            return;
                          }
                          if (contentCtrl.text.trim().isEmpty) {
                            ErrorHandler.showErrorSnackBar(ctx, '正文不能为空');
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            if (existing != null) {
                              await NewsApi.instance.updateNews(
                                existing.id!,
                                title: titleCtrl.text.trim(),
                                content: contentCtrl.text.trim(),
                                category: selectedCat,
                                coverUrl: coverCtrl.text.trim().isEmpty
                                    ? null
                                    : coverCtrl.text.trim(),
                              );
                            } else {
                              await NewsApi.instance.createNews(
                                title: titleCtrl.text.trim(),
                                content: contentCtrl.text.trim(),
                                category: selectedCat,
                                coverUrl: coverCtrl.text.trim().isEmpty
                                    ? null
                                    : coverCtrl.text.trim(),
                              );
                            }
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _loadNews(reset: true);
                            });
                          } catch (e) {
                            if (ctx.mounted) {
                              ErrorHandler.showErrorSnackBar(ctx, e);
                            }
                          } finally {
                            if (ctx.mounted) {
                              setDialogState(() => saving = false);
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(News news) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${news.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await NewsApi.instance.deleteNews(news.id!);
      if (mounted) {
        setState(() => _newsList.removeWhere((n) => n.id == news.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _logout() async {
    await Provider.of<AppProvider>(context, listen: false).logout();
  }

  List<News> get _filteredNews {
    if (_selectedCategory == null || _selectedCategory == '全部') {
      return _newsList;
    }
    return _newsList.where((n) => n.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNews;

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理后台 - 资讯管理'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory ?? '全部',
                    decoration: const InputDecoration(
                      labelText: '分类筛选',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedCategory = v == '全部' ? null : v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('新增'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _isLoading && _newsList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty && _newsList.isNotEmpty
                      ? const Center(child: Text('该分类下暂无资讯'))
                      : _newsList.isEmpty
                          ? const Center(
                              child: Text('暂无资讯，点击新增'),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount:
                                  filtered.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filtered.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _buildNewsItem(filtered[index]);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(News news) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (news.coverUrl != null && news.coverUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      news.coverUrl!,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 24),
                      ),
                    ),
                  ),
                if (news.coverUrl != null && news.coverUrl!.isNotEmpty)
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (news.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                news.category!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            news.formattedPublishTime,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(
                            '${news.viewCount ?? 0}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: '编辑',
                      onPressed: () => _showEditDialog(existing: news),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      tooltip: '删除',
                      color: Colors.red,
                      onPressed: () => _confirmDelete(news),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
