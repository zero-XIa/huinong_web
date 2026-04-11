import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/provider/app_provider.dart';

/// 问诊页面 - 使用 HTTPS POST 请求与后端通信
class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  // 图片相关
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _imagePreviews = [];
  
  // 消息列表
  final List<Map<String, dynamic>> _messages = [];
  
  // 状态管理
  bool _isSending = false;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    // 初始化 DioClient
    DioClient.instance.init('http://127.0.0.1:8000/api/v1');
    _loadHistory();
    _focusNode.addListener(_onFocusChange);
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

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      // TODO: 从后端获取历史消息
      // final history = await ConsultApi.instance.getConsultationHistory(_userId);
      // setState(() {
      //   _messages = history.map((m) => ChatMessage.fromWebSocketMessage(m)).toList();
      // });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载历史记录失败: $e')),
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
        final base64 = base64Encode(bytes);
        
        setState(() {
          _selectedImages.add(image);
          _imagePreviews.add(base64);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片选择失败: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    
    if (text.isEmpty && _selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // 添加用户消息到界面
      setState(() {
        _messages.add({
          'role': 'user',
          'content': text,
          'files': _imagePreviews,
          'isUser': true,
        });
        _controller.clear();
        _selectedImages.clear();
        _imagePreviews.clear();
      });
      
      _scrollToBottom();

      // 准备发送数据（multipart/form-data 格式）
      final FormData formData = FormData.fromMap({
        'username': 'user', // TODO: 从登录态获取
        'content': text,
        'file': _selectedImages.isNotEmpty 
          ? await MultipartFile.fromFile(_selectedImages[0].path, filename: 'file') 
          : null,
      });

      _scrollToBottom();

      // 添加正在发送的 AI 消息提示
      final pendingMessageIndex = _messages.length;
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': '正在发送...',
          'isUser': false,
          'isPending': true,
        });
      });

      _scrollToBottom();

      // 发送请求
      final response = await DioClient.instance.post<Map<String, dynamic>>(
        '/chat',
        data: formData,
      );

      // 替换正在发送的消息为实际回复
      if (mounted) {
        setState(() {
          // 后端返回格式: {"message": "...", "data": {"answer": "...", ...}}
          final answer = response['data'] is Map ? (response['data'] as Map)['answer'] : null;
          final content = answer ?? (response['message'] as String? ?? '收到您的问题，正在处理中...');
          
          // 移除正在发送的消息，添加实际回复
          _messages.removeAt(pendingMessageIndex);
          _messages.add({
            'role': 'ai',
            'content': content,
            'isUser': false,
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imagePreviews.removeAt(index);
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final isPending = message['isPending'] as bool? ?? false;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPending 
            ? Colors.grey[300]
            : (isUser ? const Color(0xFF2E7D32) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message['files'] != null) ...[
              for (final file in message['files'] as List) ...[
                if (file is String && file.startsWith('data:image'))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(file.split(',').last),
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
              ]
            ],
            const SizedBox(height: 8),
            if (isPending)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '正在发送...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              Text(
                message['content'] as String,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
          ],
        ),
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
          // 图片预览区域
          if (_imagePreviews.isNotEmpty)
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imagePreviews.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_imagePreviews[index].split(',').last),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
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
                  );
                },
              ),
            ),
          
          // 输入栏
          Row(
            children: [
              // 图片按钮
              IconButton(
                onPressed: _isSending ? null : () => _selectImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                color: const Color(0xFF2E7D32),
                disabledColor: Colors.grey,
              ),
              IconButton(
                onPressed: _isSending ? null : () => _selectImage(ImageSource.camera),
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
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
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
