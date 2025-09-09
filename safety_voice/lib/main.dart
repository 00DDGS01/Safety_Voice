import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ 추가
// import 'package:safety_voice/pages/map_screen.dart';
// import 'package:safety_voice/pages/setup_screen.dart';
// import 'package:safety_voice/pages/signup_screen.dart';
import 'package:safety_voice/pages/word_setting.dart';
import 'package:safety_voice/pages/splash_screen.dart';
// import 'pages/main_screen.dart';
// import 'pages/login_screen.dart';
// import 'pages/timetable_screen.dart';
import 'package:safety_voice/services/trigger_listener.dart';

// import 'package:safety_voice/pages/home.dart';
// import 'package:safety_voice/pages/nonamed.dart';
// import 'package:safety_voice/pages/caseFile.dart';
// import 'package:safety_voice/pages/stopRecord.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestLocationPermission(); // ✅ 위치 권한 요청
  runApp(const MyApp());
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
      title: '안전한 목소리',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Noto Sans KR',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          Future.microtask(() => triggerListener.init(context));
          //return const SplashScreen();
          return const SettingScreen();
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
