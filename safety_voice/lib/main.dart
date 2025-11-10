// lib/main.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:safety_voice/pages/splash_screen.dart';
import 'package:safety_voice/pages/home.dart';
import 'package:safety_voice/services/trigger_listener.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);
  Intl.defaultLocale = 'ko_KR';

  await requestLocationPermission();
  await _checkAndClearExpiredToken();

  // ✅ TriggerListener 전역 초기화
  await TriggerListener.instance.init(navigatorKey);

  runApp(const MyApp());
}

/// JWT 만료 토큰 처리
Future<void> _checkAndClearExpiredToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token != null && JwtDecoder.isExpired(token)) {
    print("⚠️ JWT 토큰 만료 → 삭제");
    await prefs.remove('jwt_token');
  }
}

/// 위치 권한 요청
Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;
  if (status.isDenied) {
    status = await Permission.location.request();
  }

  if (status.isGranted) {
    print("✅ 위치 권한 허용됨");
  } else if (status.isPermanentlyDenied) {
    print("❌ 위치 권한 영구 거부됨 → 설정 유도");
    await openAppSettings();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ 전역 navigatorKey 등록
      debugShowCheckedModeBanner: false,
      title: '안전한 목소리',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Noto Sans KR',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          // 테스트용으로 Splash 대신 Home으로
          return const SplashScreen();
        },
      },
    );
  }
}