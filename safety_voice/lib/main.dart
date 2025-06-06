import 'package:flutter/material.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'package:safety_voice/pages/signup_screen.dart';
import 'package:safety_voice/pages/word_setting.dart';
import 'pages/main_screen.dart';
import 'pages/login_screen.dart';
import 'pages/timetable_screen.dart';
import 'package:safety_voice/services/trigger_listener.dart';

import 'package:safety_voice/pages/listHome.dart';
import 'package:safety_voice/pages/calendarHome.dart';
import 'package:safety_voice/pages/nonamed.dart';
import 'package:safety_voice/pages/caseFile.dart';
import 'package:safety_voice/pages/stopRecord.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
          // 여기서 context를 TriggerListener에 전달
          Future.microtask(() => triggerListener.init(context));
          return const MainScreen();
        },
        '/login': (context) => const LoginScreen(),
        '/timetable': (context) => const TimeTableDemo(),
        '/signup': (context) => const SignupScreen(),
        '/setup': (context) => const SetupScreen(),
        '/safezone': (context) => const SettingScreen(),
        '/listhome': (context) => const ListHome(),
        '/calendarhome': (context) => const CalendarHome(),
        '/nonamed': (context) => const Nonamed(),
        '/casefile': (context) => const CaseFile(),
        '/stoprecord': (context) => const StopRecord(),
      },
    );
  }
}

Future<void> requestPermissions() async {
  await Permission.microphone.request();
}
