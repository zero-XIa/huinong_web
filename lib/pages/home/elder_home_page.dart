import 'package:flutter/material.dart';
import 'package:huinong_web/pages/home/home_page.dart';
import 'package:huinong_web/pages/identify/identify_page.dart';

const _cardColors = [
  Color(0xFFE53935), // 红-病害识别
  Color(0xFFFB8C00), // 橙-农业资讯
  Color(0xFF43A047), // 绿-智能问诊
  Color(0xFF1E88E5), // 蓝-识别记录
  Color(0xFF8E24AA), // 紫-历史会话
  Color(0xFF546E7A), // 灰-个人设置
];

const _cardIcons = [
  Icons.bug_report,
  Icons.article,
  Icons.chat,
  Icons.history,
  Icons.forum,
  Icons.settings,
];

const _cardLabels = [
  '病害识别',
  '农业资讯',
  '智能问诊',
  '识别记录',
  '历史会话',
  '个人设置',
];

class ElderHomePage extends StatelessWidget {
  final void Function(int tabIndex) onNavigate;

  const ElderHomePage({super.key, required this.onNavigate});

  void _handleCardTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IdentifyPage()),
        );
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      case 2:
        onNavigate(1);
      case 3:
        Navigator.pushNamed(context, '/identify/history');
      case 4:
        Navigator.pushNamed(context, '/chat/sessions');
      case 5:
        onNavigate(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '慧农长辈版',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: List.generate(6, (index) => _buildCard(context, index)),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: _cardColors[index],
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _handleCardTap(context, index),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _cardIcons[index],
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _cardLabels[index],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
