import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/connections/http_lan_connection.dart';
import 'config/app_config.dart';
import 'kits/smart_home/smart_home_api.dart';
import 'kits/smart_home/smart_home_controller.dart';
import 'screens/smart_home_screen.dart';


/// 应用程序入口函数
///
/// 初始化应用程序，设置屏幕方向为横屏，并启动应用程序。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 强制横屏模式，适合智能家居控制面板的布局
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // 隐藏状态栏和底部导航栏
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
  
  runApp(const MyApp());
}

/// 应用程序根组件
///
/// 配置应用程序的主题、路由和提供者，
/// 使用Provider模式管理全局状态。
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 注册SmartHomeController，它将自我管理其API和连接
        ChangeNotifierProvider(
          create: (_) => SmartHomeController(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Home',
        // 配置明亮卡通主题，适合儿童使用
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F8FF),
          cardColor: const Color(0xFFFFFFFF),
          primaryColor: const Color(0xFF4CAF50),
          fontFamily: 'Comic Sans MS',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF388E3C),
            ),
            bodyLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
            ),
            bodyMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E7D32),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF4CAF50),
            ),
          ),
          useMaterial3: true,
        ),
        // 设置初始路由为智能家居页面
        initialRoute: '/smart_home',
        // 配置应用程序的路由表
        routes: {
          '/smart_home': (context) => const SmartHomeScreen(),  // 智能家居页面
        },
      ),
    );
  }
}
