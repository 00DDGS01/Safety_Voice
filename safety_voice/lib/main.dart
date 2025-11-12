import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:safety_voice/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:safety_voice/pages/splash_screen.dart';
import 'package:safety_voice/services/trigger_listener.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);
  Intl.defaultLocale = 'ko_KR';

  await requestLocationPermission();
  await _checkAndClearExpiredToken();

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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: '안전한 목소리',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Noto Sans KR',
      ),
      home: const SplashWrapper(), // ✅ 아래 위젯으로 교체
    );
  }
}

/// ✅ 앱이 빌드된 후에 TriggerListener 실행하도록 래핑
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // 화면이 다 뜬 뒤 실행되도록 예약
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_initialized) {
        _initialized = true;
        print("⏳ TriggerListener 초기화 대기 중...");
        await Future.delayed(const Duration(seconds: 2)); // 약간의 여유 (Splash 중)
        await TriggerListener.instance.init(navigatorKey);
        print("✅ TriggerListener 초기화 완료 (앱 시작 후)");
      }
    });
  }

  Future<void> _loadSafeZonesFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      print("⚠️ JWT 없음 — 로그인 필요");
      return;
    }

    final url = Uri.parse("https://safetyvoice.jp.ngrok.io/api/safe-zones");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(utf8Body);

        final data = jsonData["data"];
        if (data != null && data.isNotEmpty) {
          final zone = data[0];

          await prefs.setString('safeZoneName', zone["safeZoneName"]);
          await prefs.setDouble('safeZoneLatitude', zone["latitude"]);
          await prefs.setDouble('safeZoneLongitude', zone["longitude"]);
          await prefs.setInt('safeZoneRadius', zone["radius"]);

          if (zone["safeTimes"] != null) {
            await prefs.setString(
                'safeZoneTimes', jsonEncode(zone["safeTimes"]));
          }

          print("💾 SharedPreferences에 안전지대 정보 저장 완료");
        } else {
          print("ℹ️ 서버에 저장된 안전지대 없음");
        }
      } else {
        print("❌ 서버 오류: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 안전지대 불러오기 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // 기존 스플래시 유지
  }
}
