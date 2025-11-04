import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ 추가
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:safety_voice/pages/word_setting.dart';
import 'package:safety_voice/pages/splash_screen.dart';
import 'package:safety_voice/services/trigger_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:safety_voice/pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);
  Intl.defaultLocale = 'ko_KR';

  await requestLocationPermission(); // ✅ 위치 권한 요청
  await _checkAndClearExpiredToken(); // 만료 토큰 초기화
  runApp(const MyApp());
}

/// ✅ JWT 만료 여부를 확인하고, 만료 시 SharedPreferences 초기화
Future<void> _checkAndClearExpiredToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token != null) {
    if (JwtDecoder.isExpired(token)) {
      print("⚠️ 저장된 JWT 토큰이 만료되었습니다. 삭제합니다.");
      await prefs.remove('jwt_token');
    } else {
      print("✅ JWT 토큰이 유효합니다.");
    }
  } else {
    print("ℹ️ 저장된 JWT 토큰이 없습니다.");
  }
}

/// ✅ 위치 권한 요청 함수
Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;

  if (status.isDenied) {
    status = await Permission.location.request();
  }

  if (status.isGranted) {
    print("✅ 위치 권한 허용됨!");
  } else if (status.isPermanentlyDenied) {
    print("❌ 위치 권한 영구 거부됨 → 설정으로 유도");
    await openAppSettings();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final triggerListener = TriggerListener();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '안전한 목소리',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Noto Sans KR',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          Future.microtask(() => triggerListener.init(context));
          return const SplashScreen();
          //return const Home();
        },
        // '/main': (context) => const MainScreen(),
        // '/login': (context) => const LoginScreen(),
        // '/timetable': (context) => const TimeTableDemo(),
        // '/signup': (context) => const SignupScreen(),
        // '/setup': (context) => const SetupScreen(),
        // '/safezone': (context) => const SettingScreen(),
        // '/home': (context) => const Home(),
        // '/nonamed': (context) => const Nonamed(),
        // '/casefile': (context) => const CaseFile(),
        // '/stoprecord': (context) => const StopRecord(),
        // '/mapscreen': (context) => MapScreen(),
      },
    );
  }
}

Future<void> requestPermissions() async {
  await Permission.microphone.request();
}
