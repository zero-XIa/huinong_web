import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/pages/identify/identify_page.dart';
import 'package:huinong_web/provider/app_provider.dart';

class IdentifyResultPage extends StatelessWidget {
  const IdentifyResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as IdentificationResultArguments;
    final identification = args.identification;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final elderMode = appProvider.isElderlyMode;
    final theme = Theme.of(context);

    final confidencePercent = identification.confidence != null
        ? (identification.confidence! * 100).toStringAsFixed(1)
        : '0';

    final diseaseFullName = [identification.cropName, identification.diseaseName]
        .where((e) => e != null && e.isNotEmpty)
        .join(' ');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '识别结果',
          style: TextStyle(fontSize: elderMode ? 22 : 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: identification.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseFullName.isNotEmpty ? diseaseFullName : '未识别到病害',
                      style: TextStyle(
                        fontSize: elderMode ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '置信度',
                          style: TextStyle(fontSize: elderMode ? 18 : 14),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: identification.confidence ?? 0,
                          minHeight: elderMode ? 12 : 8,
                          borderRadius: BorderRadius.circular(6),
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$confidencePercent%',
                          style: TextStyle(
                            fontSize: elderMode ? 18 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '防治建议',
                          style: TextStyle(fontSize: elderMode ? 18 : 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            identification.advice ?? '暂无防治建议',
                            style: TextStyle(
                              fontSize: elderMode ? 18 : 14,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final initialText = diseaseFullName.isNotEmpty
                            ? '我想了解关于$diseaseFullName的更多信息'
                            : null;
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: ChatPageArguments(initialText: initialText),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        minimumSize: Size(double.infinity, elderMode ? 56 : 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(elderMode ? 12 : 8),
                        ),
                      ),
                      child: Text(
                        '继续问诊',
                        style: TextStyle(fontSize: elderMode ? 19 : 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, elderMode ? 56 : 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(elderMode ? 12 : 8),
                        ),
                      ),
                      child: Text(
                        '返回首页',
                        style: TextStyle(fontSize: elderMode ? 19 : 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPageArguments {
  final String? initialText;

  ChatPageArguments({this.initialText});
}