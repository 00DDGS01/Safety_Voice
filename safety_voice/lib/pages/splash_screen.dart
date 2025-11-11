// lib/pages/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:safety_voice/pages/login_screen.dart';
import 'package:safety_voice/pages/main_screen.dart'; // 경로는 실제 파일에 맞게 조정
import 'dart:async';
import 'package:safety_voice/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Widget nextScreen = (token != null && token.isNotEmpty)
          ? const MainScreen()
          : const LoginScreen();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextScreen,
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds:700),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B7AFF), // 파란 배경
      body: Center(
        child: Image.asset('assets/logo1.png'),
      ),
    );
  }
}