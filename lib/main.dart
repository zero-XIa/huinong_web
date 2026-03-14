
import 'package:flutter/material.dart';
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/pages/home/home_page.dart';
import 'package:huinong_web/pages/consult/consult_page.dart';
import 'package:huinong_web/pages/mine/mine_page.dart';
import 'package:huinong_web/provider/app_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DioClient.instance.init('http://127.0.0.1:8000/api/v1'); // 初始化 Dio
  final appProvider = AppProvider();
  await appProvider.loadElderlyMode(); // 加载适老化模式
  runApp(
    ChangeNotifierProvider(
      create: (context) => appProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '慧农 App',
      theme: ThemeData(
        primarySwatch: Colors.green, // 符合 Google 原生简洁风格，以绿色为主色调
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // 统一 Card 样式
        cardTheme: CardThemeData(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // 统一圆角
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0), // 统一列表项间距
        ),
        // 统一 ElevatedButton 样式
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle( // 直接使用 ButtonStyle
            backgroundColor: WidgetStateProperty.all(const Color(0xFF2E7D32)), // 主色 #2E7D32
            foregroundColor: WidgetStateProperty.all(Colors.white), // 文字颜色
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // 统一圆角
            )),
            // hover 反馈
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.hovered)) {
                  return Colors.white.withAlpha(26); // 0.1 opacity ≈ 26 alpha
                }
                return null;
              },
            ),
          ),
        ),
        // 统一输入框样式
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0), // 统一圆角
            borderSide: BorderSide.none, // 默认无边框
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2.0), // 聚焦时主色边框
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          filled: true,
          fillColor: Colors.grey[100], // 默认填充色
        ),
      ),
      home: const MainScreen(), // 使用 MainScreen 作为应用的根页面
    );
  }
}

/// 主屏幕，包含底部导航栏和页面切换逻辑
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 当前选中的底部导航栏索引

  // 页面列表，稍后会替换为实际的页面
  final List<Widget> _pages = [
    const HomePage(), // 首页
    const ConsultPage(), // 问诊页面
    const MinePage(), // 我的页面
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: '问诊',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
