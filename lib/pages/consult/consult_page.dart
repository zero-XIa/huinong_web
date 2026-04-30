import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/chat_api.dart';
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/provider/app_provider.dart';

/// 打字指示器组件 - 显示三个跳动的圆点
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _dot1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );
    _dot2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
      ),
    );
    _dot3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(_dot1Animation),
        _buildDot(_dot2Animation),
        _buildDot(_dot3Animation),
      ],
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -8 * animation.value),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF9E9E9E),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 问诊页面 - 使用 HTTPS POST 请求与后端通信
class ConsultPage extends StatefulWidget {
  final String? initialText;

  const ConsultPage({super.key, this.initialText});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  // 图片相关 - 只支持单张图片
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  
  // 消息列表
  final List<Map<String, dynamic>> _messages = [];
  
  // 状态管理
  bool _isSending = false;
  bool _isLoadingHistory = false;
  bool _isAITyping = false;
  
  // Session 管理
  String? _currentSessionId;
  String? _initialSessionId;
  bool _fromHistory = false;

  @override
  void initState() {
    super.initState();
    DioClient.instance.init('http://127.0.0.1:8000/api/v1');
    _focusNode.addListener(_onFocusChange);
    
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.text = widget.initialText!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is Map<String, dynamic>) {
      final sessionId = args['sessionId'] as String?;
      final fromHistory = args['fromHistory'] as bool? ?? false;
      
      if (sessionId != null && _initialSessionId == null) {
        _initialSessionId = sessionId;
        _loadHistoryBySessionId(_initialSessionId!);
      }
      
      if (fromHistory) {
        _fromHistory = true;
      }
    } else if (args is String && _initialSessionId == null) {
      _initialSessionId = args;
      _loadHistoryBySessionId(_initialSessionId!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _loadHistoryBySessionId(String sessionId) async {
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      final response = await ChatApi.instance.getMessages(sessionId, skip: 0, limit: 50);
      final List<Map<String, dynamic>> historyMessages = (response['list'] as List)
          .map((json) => {
                'role': json['role'] as String,
                'content': json['content'] as String,
                'files': [],
                'isUser': (json['role'] as String) == 'user',
              })
          .toList();
      
      setState(() {
        _messages.clear();
        _messages.addAll(historyMessages);
        _currentSessionId = sessionId;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载历史记录失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片选择失败：$e')),
        );
      }
    }
  }

  Future<void> _sendTextMessage(String content) async {
    if (content.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      setState(() {
        _messages.add({
          'role': 'user',
          'content': content,
          'files': [],
          'isUser': true,
        });
        _controller.clear();
      });
      
      _scrollToBottom();

      setState(() {
        _isAITyping = true;
      });

      final response = await ChatApi.instance.sendTextMessage(
        content,
        sessionId: _currentSessionId,
      );

      if (mounted) {
        setState(() {
          _isAITyping = false;
          
          final answer = response['answer'] as String? ?? '收到您的问题，正在处理中...';
          final sessionId = response['session_id'] as String?;
          
          if (sessionId != null && _currentSessionId == null) {
            _currentSessionId = sessionId;
          }
          
          _messages.add({
            'role': 'ai',
            'content': answer,
            'isUser': false,
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAITyping = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendImageMessage(XFile imageFile, {String? text}) async {
    setState(() {
      _isSending = true;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      
      setState(() {
        _messages.add({
          'role': 'user',
          'content': text ?? '',
          'files': [bytes],
          'isUser': true,
        });
        _controller.clear();
        _selectedImage = null;
        _imageBytes = null;
      });
      
      _scrollToBottom();

      setState(() {
        _isAITyping = true;
      });

      final response = await ChatApi.instance.sendImageMessage(
        imageFile,
        text: text,
        sessionId: _currentSessionId,
      );

      if (mounted) {
        setState(() {
          _isAITyping = false;
          
          final answer = response['answer'] as String? ?? '收到您的问题，正在处理中...';
          final sessionId = response['session_id'] as String?;
          
          if (sessionId != null && _currentSessionId == null) {
            _currentSessionId = sessionId;
          }
          
          _messages.add({
            'role': 'ai',
            'content': answer,
            'isUser': false,
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAITyping = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    
    if (text.isEmpty && _selectedImage == null) {
      return;
    }

    if (_selectedImage != null) {
      await _sendImageMessage(_selectedImage!, text: text);
    } else {
      await _sendTextMessage(text);
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;
    final fontSize = isElderMode ? 18.0 : 14.0;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2E7D32) : Colors.grey[200],
          borderRadius: BorderRadius.circular(isElderMode ? 16 : 12),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message['files'] != null) ...[
              for (final file in message['files'] as List) ...[
                if (file is Uint8List)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isElderMode ? 12 : 8),
                    child: Image.memory(
                      file,
                      width: isElderMode ? 180 : 150,
                      height: isElderMode ? 180 : 150,
                      fit: BoxFit.cover,
                    ),
                  ),
              ]
            ],
            const SizedBox(height: 8),
            Text(
              message['content'] as String,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicatorMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TypingIndicator(),
      ),
    );
  }

  Widget _buildInputArea() {
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;
    
    final double padding = isElderMode ? 20.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图片预览区域（单张）
          if (_imageBytes != null)
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageBytes!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: _clearImage,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // 输入栏
          Row(
            children: [
              // 图片按钮
              IconButton(
                onPressed: _isSending || _selectedImage != null ? null : () => _selectImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                color: const Color(0xFF2E7D32),
                disabledColor: Colors.grey,
              ),
              IconButton(
                onPressed: _isSending || _selectedImage != null ? null : () => _selectImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                color: const Color(0xFF2E7D32),
                disabledColor: Colors.grey,
              ),
              
              // 输入框
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '请输入您的问题...',
                    hintStyle: TextStyle(
                      fontSize: 14.0,
                      color: Color(0xFF9E9E9E),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              
              // 发送按钮
              IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
                color: const Color(0xFF2E7D32),
                disabledColor: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;
    
    final double padding = isElderMode ? 20.0 : 8.0;
    const Color elderTextColor = Color(0xFF333333);
    const Color elderBackgroundColor = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: isElderMode ? elderBackgroundColor : null,
      appBar: AppBar(
        title: Text(
          '在线问诊',
          style: TextStyle(
            fontSize: isElderMode ? 22.0 : 16.0,
            color: isElderMode ? elderTextColor : null,
          ),
        ),
        backgroundColor: isElderMode ? elderBackgroundColor : null,
        elevation: 0,
        actions: _fromHistory
          ? []
          : [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.pushNamed(context, '/chat/sessions');
                },
                tooltip: '历史会话',
                iconSize: isElderMode ? 28 : 24,
              ),
            ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                ? const Center(
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
                          '暂无消息',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(padding),
                    itemCount: _messages.length + (_isAITyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 如果是最后一个位置且正在等待，显示 TypingIndicator
                      if (_isAITyping && index == _messages.length) {
                        return _buildTypingIndicatorMessage();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          
          // 底部输入栏
          _buildInputArea(),
        ],
      ),
    );
  }
}
