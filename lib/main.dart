import 'package:flutter/material.dart';
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/pages/chat/sessions_page.dart';
import 'package:huinong_web/pages/consult/consult_page.dart';
import 'package:huinong_web/pages/home/home_page.dart';
import 'package:huinong_web/pages/identify/identify_history_page.dart';
import 'package:huinong_web/pages/identify/identify_page.dart';
import 'package:huinong_web/pages/identify/identify_result_page.dart';
import 'package:huinong_web/pages/login/login_page.dart';
import 'package:huinong_web/pages/mine/mine_page.dart';
import 'package:huinong_web/provider/app_provider.dart';
import 'package:provider/provider.dart';

// 全局导航键，用于非 Widget 环境的导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Dio 客户端
  DioClient.instance.init('http://127.0.0.1:8000/api/v1');
  
  // 创建 AppProvider 实例
  final appProvider = AppProvider();
  
  // 设置 AppProvider 实例到 DioClient
  DioClient.setAppProvider(appProvider);
  
  // 检查登录状态
  await appProvider.checkLoginStatus();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => appProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(bool isElderMode) {
    final baseTheme = ThemeData(
      primarySwatch: Colors.green,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    if (isElderMode) {
      debugPrint('[MAIN] 构建主题，模式: 适老');
      return baseTheme.copyWith(
        cardTheme: CardThemeData(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 12.0),
          color: const Color(0xFFF5F5DC),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF2E7D32)),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0)),
            minimumSize: WidgetStateProperty.all(const Size.fromHeight(50)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            )),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(const TextStyle(inherit: true, fontSize: 18.0)),
            minimumSize: WidgetStateProperty.all(const Size(80, 50)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          filled: true,
          fillColor: const Color(0xFFF5F5DC),
          labelStyle: const TextStyle(fontSize: 18.0, color: Color(0xFF333333)),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0, color: Color(0xFF333333)),
          bodyMedium: TextStyle(fontSize: 18.0, color: Color(0xFF333333)),
          titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          titleMedium: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
      );
    }

    debugPrint('[MAIN] 构建主题，模式: 默认');
    return baseTheme.copyWith(
      cardTheme: CardThemeData(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF2E7D32)),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          )),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.white.withAlpha(26);
              }
              return null;
            },
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, appProvider, _) {
        debugPrint('[MAIN] 主题重建，当前 isElderlyMode: ${appProvider.isElderlyMode}');
        return MaterialApp(
          title: '慧农 App',
          navigatorKey: navigatorKey,
          routes: {
            '/identify/result': (context) => const IdentifyResultPage(),
            '/identify/history': (context) => const IdentifyHistoryPage(),
            '/chat': (context) => ConsultPage(
                  initialText: ModalRoute.of(context)?.settings.arguments is ChatPageArguments
                      ? (ModalRoute.of(context)!.settings.arguments as ChatPageArguments).initialText
                      : null,
                ),
            '/chat/sessions': (context) => const SessionsPage(),
          },
          theme: _buildTheme(appProvider.isElderlyMode),
          home: appProvider.isLoggedIn ? const MainScreen() : const LoginPage(),
        );
      },
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
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const IdentifyPage(),
    const ConsultPage(),
    const MinePage(),
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
            icon: Icon(Icons.camera_alt),
            label: '识别',
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
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
      ),
    );
  }
}
