import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:huinong_web/api/identify_api.dart';
import 'package:huinong_web/models/identification_model.dart';
import 'package:huinong_web/utils/error_handler.dart';
import 'package:huinong_web/widgets/loading_indicator.dart';

class IdentifyPage extends StatefulWidget {
  const IdentifyPage({super.key});

  @override
  State<IdentifyPage> createState() => _IdentifyPageState();
}

class _IdentifyPageState extends State<IdentifyPage> {
  XFile? _selectedImage;
  bool _isIdentifying = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (await _validateImage(pickedFile)) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    }
  }

  Future<bool> _validateImage(XFile file) async {
    if (!mounted) return false;
    
    final allowedExtensions = ['jpg', 'jpeg', 'png'];
    final fileName = file.name.toLowerCase();
    final extension = fileName.split('.').last;
    
    if (!allowedExtensions.contains(extension)) {
      ErrorHandler.showErrorSnackBar(context, '请选择 jpg 或 png 格式的图片');
      return false;
    }

    final fileSize = await file.length();
    if (!mounted) return false;
    
    const maxSize = 10 * 1024 * 1024;
    if (fileSize > maxSize) {
      ErrorHandler.showErrorSnackBar(context, '图片大小不能超过 10MB');
      return false;
    }

    return true;
  }

  Future<void> _startIdentify() async {
    if (_selectedImage == null) return;

    setState(() {
      _isIdentifying = true;
    });

    LoadingIndicator.show(context);

    try {
      final result = await IdentifyApi.instance.identify(_selectedImage!);
      if (!mounted) return;
      LoadingIndicator.hide(context);
      await Navigator.pushNamed(
        context,
        '/identify/result',
        arguments: IdentificationResultArguments(result),
      );
    } catch (e, stackTrace) {
      debugPrint('识别失败详情: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      if (!mounted) return;
      LoadingIndicator.hide(context);
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isIdentifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '病害识别',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '识别历史',
            onPressed: () {
              Navigator.pushNamed(context, '/identify/history');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.contain,
                              )
                            : Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.contain,
                              ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '点击下方按钮选择图片',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isIdentifying ? null : () => _pickImage(ImageSource.camera),
                      child: const Text('拍照'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isIdentifying ? null : () => _pickImage(ImageSource.gallery),
                      child: const Text('从相册选择'),
                    ),
                  ),
                ],
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ElevatedButton(
                    onPressed: _isIdentifying ? null : _startIdentify,
                    child: _isIdentifying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            '开始识别',
                            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class IdentificationResultArguments {
  final Identification identification;

  IdentificationResultArguments(this.identification);
}