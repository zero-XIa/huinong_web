import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/identify_api.dart';
import 'package:huinong_web/models/identification_model.dart';
import 'package:huinong_web/pages/identify/identify_page.dart';
import 'package:huinong_web/pages/identify/identify_result_page.dart';
import 'package:huinong_web/provider/app_provider.dart';
import 'package:huinong_web/utils/error_handler.dart';

class IdentifyHistoryPage extends StatefulWidget {
  const IdentifyHistoryPage({super.key});

  @override
  State<IdentifyHistoryPage> createState() => _IdentifyHistoryPageState();
}

class _IdentifyHistoryPageState extends State<IdentifyHistoryPage> {
  final List<Identification> _history = [];
  int _skip = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _hasError = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final isLoggedIn = context.read<AppProvider>().isLoggedIn;
    if (isLoggedIn) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      if (reset) {
        _skip = 0;
        _history.clear();
        _hasMore = true;
      }
    });

    try {
      final response = await IdentifyApi.instance.getHistory(
        skip: _skip,
        limit: 10,
      );

      final List<dynamic> list = response['list'] ?? [];
      final int total = response['total'] ?? 0;

      setState(() {
        _history.addAll(list
            .map((item) => Identification.fromJson(item as Map<String, dynamic>))
            .toList());
        _skip += list.length;
        _hasMore = _history.length < total;
      });
    } catch (e) {
      ErrorHandler.logError('IdentifyHistory', e);
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadHistory(reset: true);
  }

  Future<void> _deleteItem(int id, int index) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条识别记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await IdentifyApi.instance.deleteHistory(id);
      if (!mounted) return;
      setState(() {
        _history.removeAt(index);
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  void _goToDetail(Identification identification) {
    Navigator.pushNamed(
      context,
      '/identify/result',
      arguments: IdentificationResultArguments(identification),
    );
  }

  void _goToChat(Identification identification) {
    final diseaseName = identification.diseaseName ?? identification.cropName;
    final initialText = diseaseName != null && diseaseName.isNotEmpty
        ? '我想了解关于$diseaseName的更多信息'
        : null;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: ChatPageArguments(initialText: initialText),
    );
  }

  Widget _buildListItem(
      BuildContext context, Identification item, bool elderMode) {
    final confidencePercent = item.confidence != null
        ? (item.confidence! * 100).toStringAsFixed(1)
        : '0';
    final diseaseFullName = [item.cropName, item.diseaseName]
        .where((e) => e != null && e.isNotEmpty)
        .join(' ');

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        await _deleteItem(item.id as int, _history.indexOf(item));
        return false;
      },
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: elderMode ? 16 : 12,
          vertical: elderMode ? 12 : 8,
        ),
        child: InkWell(
          onTap: () => _goToDetail(item),
          child: Padding(
            padding: EdgeInsets.all(elderMode ? 16 : 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: elderMode ? 80 : 60,
                    height: elderMode ? 80 : 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diseaseFullName.isNotEmpty
                            ? diseaseFullName
                            : '未识别到病害',
                        style: TextStyle(
                          fontSize: elderMode ? 18 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '置信度 $confidencePercent%',
                              style: TextStyle(
                                fontSize: elderMode ? 14 : 12,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.formattedCreateTime,
                            style: TextStyle(
                              fontSize: elderMode ? 14 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _goToChat(item),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(elderMode ? 80 : 60, elderMode ? 40 : 32),
                              padding: EdgeInsets.symmetric(
                                horizontal: elderMode ? 12 : 8,
                                vertical: elderMode ? 8 : 4,
                              ),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                            child: Text(
                              '继续问诊',
                              style: TextStyle(
                                fontSize: elderMode ? 14 : 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final elderMode = appProvider.isElderlyMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_search,
            size: elderMode ? 80 : 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无识别记录',
            style: TextStyle(
              fontSize: elderMode ? 20 : 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHistory,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, elderMode ? 56 : 48),
            ),
            child: Text(
              '去识别',
              style: TextStyle(fontSize: elderMode ? 19 : 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final elderMode = appProvider.isElderlyMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: elderMode ? 80 : 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: elderMode ? 20 : 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHistory,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, elderMode ? 56 : 48),
            ),
            child: Text(
              '重新加载',
              style: TextStyle(fontSize: elderMode ? 19 : 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final elderMode = appProvider.isElderlyMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '识别历史',
          style: TextStyle(fontSize: elderMode ? 22 : 18),
        ),
      ),
      body: _hasError
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _history.isEmpty
                  ? _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(elderMode ? 16 : 8),
                      itemCount: _history.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _history.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildListItem(context, _history[index], elderMode);
                      },
                    ),
            ),
    );
  }
}