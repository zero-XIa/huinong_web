import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/chat_api.dart';
import 'package:huinong_web/models/chat_session.dart';
import 'package:huinong_web/provider/app_provider.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final List<ChatSession> _sessions = [];
  int _skip = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  
  bool _isEditingMode = false;
  final Set<String> _selectedSessionIds = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading && 
        _hasMore) {
      _loadSessions();
    }
  }

  Future<void> _loadSessions({bool reset = false}) async {
    if (reset) {
      _skip = 0;
      _sessions.clear();
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final response = await ChatApi.instance.getSessions(skip: _skip, limit: 20);
      final list = (response['list'] as List)
          .map((json) => ChatSession.fromJson(json))
          .toList();
      setState(() {
        _sessions.addAll(list);
        _skip += list.length;
        _hasMore = _sessions.length < (response['total'] as int);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载会话失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadSessions(reset: true);
  }

  void _toggleEditingMode() {
    setState(() {
      _isEditingMode = !_isEditingMode;
      if (!_isEditingMode) {
        _selectedSessionIds.clear();
      }
    });
  }

  void _toggleSelectSession(String sessionId) {
    setState(() {
      if (_selectedSessionIds.contains(sessionId)) {
        _selectedSessionIds.remove(sessionId);
      } else {
        _selectedSessionIds.add(sessionId);
      }
    });
  }

  void _selectAllSessions() {
    setState(() {
      if (_selectedSessionIds.length == _sessions.length) {
        _selectedSessionIds.clear();
      } else {
        _selectedSessionIds.addAll(_sessions.map((s) => s.sessionId));
      }
    });
  }

  Future<void> _batchDeleteSessions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedSessionIds.length} 个会话吗？'),
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
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      for (final sessionId in _selectedSessionIds) {
        await ChatApi.instance.deleteSession(sessionId);
      }
      
      if (mounted) {
        setState(() {
          _sessions.removeWhere((s) => _selectedSessionIds.contains(s.sessionId));
          _selectedSessionIds.clear();
          _isEditingMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量删除失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSession(String sessionId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个会话吗？'),
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
    );

    if (confirm != true) return;

    try {
      await ChatApi.instance.deleteSession(sessionId);
      if (mounted) {
        setState(() {
          _sessions.removeAt(index);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Widget _buildSessionItem(ChatSession session, int index) {
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;
    final fontSize = isElderMode ? 18.0 : 14.0;
    final titleFontSize = isElderMode ? 16.0 : 14.0;
    final isSelected = _selectedSessionIds.contains(session.sessionId);

    final tileContent = ListTile(
      leading: _isEditingMode
          ? Transform.scale(
              scale: isElderMode ? 1.2 : 1.0,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleSelectSession(session.sessionId),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          : Container(
              width: isElderMode ? 60 : 50,
              height: isElderMode ? 60 : 50,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: isElderMode ? 28 : 24,
              ),
            ),
      title: Text(
        session.title.isNotEmpty ? session.title : '问诊对话',
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        session.formattedTime,
        style: TextStyle(
          fontSize: fontSize * 0.8,
          color: Colors.grey[600],
        ),
      ),
    );

    if (_isEditingMode) {
      return InkWell(
        onTap: () => _toggleSelectSession(session.sessionId),
        child: tileContent,
      );
    }

    return Dismissible(
      key: Key(session.sessionId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        await _deleteSession(session.sessionId, index);
        return false;
      },
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {'sessionId': session.sessionId, 'fromHistory': true},
          );
        },
        leading: Container(
          width: isElderMode ? 60 : 50,
          height: isElderMode ? 60 : 50,
          decoration: const BoxDecoration(
            color: Color(0xFF2E7D32),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: isElderMode ? 28 : 24,
          ),
        ),
        title: Text(
          session.title.isNotEmpty ? session.title : '问诊对话',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          session.formattedTime,
          style: TextStyle(
            fontSize: fontSize * 0.8,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Color(0xFF9E9E9E),
          ),
          SizedBox(height: 16),
          Text(
            '暂无会话',
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;
    const Color elderTextColor = Color(0xFF333333);
    const Color elderBackgroundColor = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: isElderMode ? elderBackgroundColor : null,
      appBar: AppBar(
        title: _isEditingMode
            ? Text(
                '选择会话 (${_selectedSessionIds.length})',
                style: TextStyle(
                  fontSize: isElderMode ? 22.0 : 16.0,
                  color: isElderMode ? elderTextColor : null,
                ),
              )
            : Text(
                '历史会话',
                style: TextStyle(
                  fontSize: isElderMode ? 22.0 : 16.0,
                  color: isElderMode ? elderTextColor : null,
                ),
              ),
        backgroundColor: isElderMode ? elderBackgroundColor : null,
        elevation: 0,
        leading: _isEditingMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleEditingMode,
                iconSize: isElderMode ? 28 : 24,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                iconSize: isElderMode ? 28 : 24,
              ),
        actions: _isEditingMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAllSessions,
                  iconSize: isElderMode ? 28 : 24,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedSessionIds.isNotEmpty ? _batchDeleteSessions : null,
                  iconSize: isElderMode ? 28 : 24,
                  color: Colors.red,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _sessions.isNotEmpty ? _toggleEditingMode : null,
                  iconSize: isElderMode ? 28 : 24,
                ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading && _sessions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _sessions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _sessions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _sessions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildSessionItem(_sessions[index], index);
                    },
                  ),
      ),
    );
  }
}