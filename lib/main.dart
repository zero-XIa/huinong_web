import 'package:flutter/material.dart';
import 'package:huinong_web/api/dio_client.dart';
import 'package:huinong_web/pages/admin/admin_news_page.dart';
import 'package:huinong_web/pages/chat/sessions_page.dart';
import 'package:huinong_web/pages/consult/consult_page.dart';
import 'package:huinong_web/pages/home/home_page.dart';
import 'package:huinong_web/pages/home/elder_home_page.dart';
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

  static ThemeData _buildTheme(bool isElderMode) {
    final baseTheme = ThemeData(
      primarySwatch: Colors.green,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    if (isElderMode) {
      debugPrint('[MAIN] 构建主题，模式: 适老');
      return baseTheme.copyWith(
        primaryColor: const Color(0xFF00C853),
        cardTheme: CardThemeData(
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 16.0),
          color: const Color(0xFFFFFFFF),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF00C853)),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0)),
            minimumSize: WidgetStateProperty.all(const Size.fromHeight(64)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            )),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 22.0)),
            minimumSize: WidgetStateProperty.all(const Size(80, 64)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: const BorderSide(color: Color(0xFF00C853), width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 22.0),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          labelStyle: const TextStyle(fontSize: 22.0, color: Color(0xFF000000)),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 22.0, color: Color(0xFF000000)),
          bodyMedium: TextStyle(fontSize: 22.0, color: Color(0xFF000000)),
          titleLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
          titleMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
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
    // MaterialApp 在 MyApp.build 中只创建一次，通过 _AppShell 下沉可变逻辑，
    // 避免 MaterialApp 重建导致 navigatorKey 的 GlobalKey 冲突。
    return MaterialApp(
      title: '慧农 App',
      navigatorKey: navigatorKey,
      routes: {
        '/identify/result': (context) => const IdentifyResultPage(),
        '/identify/history': (context) => const IdentifyHistoryPage(),
        '/chat': (context) => ConsultPage(
              initialText: ModalRoute.of(context)?.settings.arguments is ChatPageArguments
                  ? _extractChatPageArguments(context)
                  : null,
            ),
        '/chat/sessions': (context) => const SessionsPage(),
        '/admin': (context) => const AdminNewsPage(),
      },
      theme: _buildTheme(false),
      home: const _AppShell(),
    );
  }
}

/// 提取 ChatPageArguments 中的 initialText 参数
/// 实现逻辑：从 ModalRoute 的 settings.arguments 中安全读取 initialText
dynamic _extractChatPageArguments(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args is ChatPageArguments) {
    return (args).initialText;
  }
  return null;
}

/// 应用壳层组件，负责监听 AppProvider 状态变化并决定当前显示的页面和主题。
///
/// 实现逻辑：
/// 1. 使用 context.select 精确定向监听 isLoggedIn、isAdmin、isElderlyMode 三个状态。
/// 2. MaterialApp 本身永不重建，_AppShell 的变化只在壳层内发生，不会触发 navigatorKey 冲突。
/// 3. 长辈模式变化时通过 Theme 包装切换主题，登录状态变化时切换 home 页面。
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    // 精确定向监听：只监听各自关心的状态片段，避免无关状态变化触发不必要的重建
    final isLoggedIn = context.select<AppProvider, bool>((p) => p.isLoggedIn);
    final isAdmin = context.select<AppProvider, bool>((p) => p.currentUser?.role == 'admin');
    final isElder = context.select<AppProvider, bool>((p) => p.isElderlyMode);

    debugPrint('[SHELL] 重建, isLoggedIn: $isLoggedIn, isAdmin: $isAdmin, isElder: $isElder');

    // 根据登录状态和角色决定根页面
    Widget page;
    if (!isLoggedIn) {
      page = const LoginPage();
    } else if (isAdmin) {
      page = const AdminNewsPage();
    } else {
      page = const MainScreen();
    }

    // 长辈模式通过 Theme 包装注入，不重建 MaterialApp
    // 使用 ValueKey 确保主题切换时直接替换 widget，避免 AnimatedTheme 插值
    return Theme(
      key: ValueKey('theme_$isElder'),
      data: MyApp._buildTheme(isElder),
      child: page,
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
  bool _prevElderMode = false;

  final List<Widget Function()> _pageBuilders = [
    () => const HomePage(),
    () => const IdentifyPage(),
    () => const ConsultPage(),
    () => const MinePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isElderMode = context.watch<AppProvider>().isElderlyMode;

    // 仅在长辈模式 OFF->ON 的瞬间跳转到首页，避免后续点击"我的"Tab 被反复重置
    if (isElderMode && !_prevElderMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }
    _prevElderMode = isElderMode;

    if (isElderMode) {
      final index = _selectedIndex.clamp(0, 2);
      return Scaffold(
        body: index == 0
            ? ElderHomePage(
                onNavigate: (tabIndex) {
                  setState(() {
                    _selectedIndex = tabIndex;
                  });
                },
              )
            : index == 1
                ? const ConsultPage(key: ValueKey('elder_consult'))
                : const MinePage(key: ValueKey('elder_mine')),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 36),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat, size: 36),
              label: '问诊',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 36),
              label: '我的',
            ),
          ],
          currentIndex: index,
          selectedItemColor: const Color(0xFF00C853),
          selectedLabelStyle: const TextStyle(fontSize: 18),
          unselectedLabelStyle: const TextStyle(fontSize: 18),
          onTap: _onItemTapped,
        ),
      );
    }

    return Scaffold(
      body: _pageBuilders[_selectedIndex](),
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
