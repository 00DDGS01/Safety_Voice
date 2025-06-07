import 'package:flutter/material.dart';
import 'package:safety_voice/pages/test.dart'; // CalendarHome이 test.dart에 있으면 경로에 맞게

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '안전한 목소리',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Noto Sans KR',
      ),
      home: CalendarHome(), // 👈 앱 실행 시 바로 test.dart로 이동
    );
  }
}
