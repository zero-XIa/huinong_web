import 'package:flutter/material.dart';
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
  late Future<List<News>> _newsListFuture;

  @override
  void initState() {
    super.initState();
    _newsListFuture = NewsApi.instance.getNewsList();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isElderMode = appProvider.isElderlyMode;

    // 适老化样式配置
    final double baseFontSize = isElderMode ? 18.0 : 14.0;
    final double titleFontSize = isElderMode ? 22.0 : 16.0;
    final double padding = isElderMode ? 20.0 : 8.0;
    const Color elderTextColor = Color(0xFF333333);
    const Color elderBackgroundColor = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: isElderMode ? elderBackgroundColor : null,
      appBar: AppBar(
        title: Text(
          '智慧农业',
          style: TextStyle(
            fontSize: isElderMode ? titleFontSize : null,
            color: isElderMode ? elderTextColor : null,
          ),
        ),
        actions: [
          Switch(
            value: isElderMode,
            onChanged: (value) {
              appProvider.toggleElderlyMode();
            },
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey,
          ),
        ],
      ),
      body: FutureBuilder<List<News>>(
        future: _newsListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('暂无新闻数据'));
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(padding),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final news = snapshot.data![index];
                return Card(
                  elevation: isElderMode ? 4.0 : null,
                  margin: EdgeInsets.only(bottom: padding),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.title,
                          style: TextStyle(
                            fontSize: isElderMode ? titleFontSize : null,
                            fontWeight: FontWeight.bold,
                            color: isElderMode ? elderTextColor : null,
                          ),
                        ),
                        SizedBox(height: padding / 2),
                        Text(
                          news.content,
                          style: TextStyle(
                            fontSize: isElderMode ? baseFontSize : null,
                            color: isElderMode ? elderTextColor : null,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: padding / 2),
                        Text(
                          news.formattedPublishTime,
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
    );
  }
}
