import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:huinong_web/api/consult_api.dart';
import 'package:huinong_web/models/identification_model.dart';
import 'package:huinong_web/provider/app_provider.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  final TextEditingController _consultController = TextEditingController();
  final FocusNode _consultFocusNode = FocusNode();
  Future<List<Identification>>? _historyFuture;

  // 临时硬编码用户ID
  final int _userId = 1;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _consultController.dispose();
    _consultFocusNode.dispose();
    super.dispose();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = ConsultApi.instance.getConsultationHistory(_userId);
    });
  }

  Future<void> _submitConsultation() async {
    if (_consultController.text.trim().isEmpty) {
      return;
    }

    // 模拟提交成功，清空输入框并刷新历史记录
    setState(() {
      _consultController.clear();
      _consultFocusNode.unfocus(); // 提交后取消焦点
      _loadHistory(); // 重新加载历史记录
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('问诊提交成功！')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;

    // 适老化样式配置
    final double baseFontSize = isElderMode ? 18.0 : 14.0;
    final double titleFontSize = isElderMode ? 22.0 : 16.0;
    final double buttonTextFontSize = isElderMode ? 20.0 : 16.0;
    final double padding = isElderMode ? 20.0 : 8.0;
    final double buttonHeight = isElderMode ? 50.0 : 40.0;
    const Color elderTextColor = Color(0xFF333333);
    const Color elderBackgroundColor = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: isElderMode ? elderBackgroundColor : null,
      appBar: AppBar(
        title: Text(
          '在线问诊',
          style: TextStyle(
            fontSize: isElderMode ? titleFontSize : null,
            color: isElderMode ? elderTextColor : null,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Identification>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('加载历史失败: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('暂无问诊历史'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final record = snapshot.data![index];
                        return Card(
                          elevation: isElderMode ? 4.0 : null,
                          margin: EdgeInsets.only(bottom: padding),
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '作物名称: ${record.diseaseName ?? '未知'}',
                                  style: TextStyle(
                                    fontSize: isElderMode ? titleFontSize : null,
                                    fontWeight: FontWeight.bold,
                                    color: isElderMode ? elderTextColor : null,
                                  ),
                                ),
                                SizedBox(height: padding / 2),
                                Text(
                                  '识别结果: ${record.advice ?? '暂无建议'}',
                                  style: TextStyle(
                                    fontSize: isElderMode ? baseFontSize : null,
                                    color: isElderMode ? elderTextColor : null,
                                  ),
                                ),
                                SizedBox(height: padding / 2),
                                Text(
                                  '识别时间: ${record.formattedCreateTime}',
                                  style: TextStyle(
                                    fontSize: isElderMode ? baseFontSize * 0.9 : null,
                                    color: isElderMode ? elderTextColor.withAlpha(179) : Colors.grey, // 0.7 opacity ≈ 179 alpha
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            SizedBox(height: padding),
            TextField(
              controller: _consultController,
              focusNode: _consultFocusNode,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontSize: isElderMode ? baseFontSize : null,
                color: isElderMode ? elderTextColor : null,
              ),
              decoration: InputDecoration(
                hintText: '请输入您的问题...',
                hintStyle: TextStyle(
                  fontSize: isElderMode ? baseFontSize : null,
                  color: isElderMode ? elderTextColor.withAlpha(153) : null, // 0.6 opacity ≈ 153 alpha
                ),
                border: const OutlineInputBorder(),
                focusedBorder: isElderMode
                    ? OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      )
                    : null,
                contentPadding: EdgeInsets.all(padding),
              ),
            ),
            SizedBox(height: padding),
            SizedBox(
              height: buttonHeight, // 适老化按钮高度
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _consultController.text.trim().isNotEmpty ? _submitConsultation : null,
                style: isElderMode
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(fontSize: buttonTextFontSize),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      )
                    : null, // 非适老化模式下使用主题默认样式
                child: Text(
                  '提交',
                  style: TextStyle(fontSize: isElderMode ? buttonTextFontSize : null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
