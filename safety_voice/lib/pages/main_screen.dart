import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // 화면 크기 가져오기
    final double logoHeight = size.height * 0.6; // 화면 높이의 35% 크기
    final double buttonWidth = size.width * 0.75; // 화면 너비의 80%
    final double buttonHeight = size.height * 0.07; // 화면 높이의 6%

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.1),
              Image.asset(
                'assets/logo.png',
                height: logoHeight-130,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                child: Column(
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '로그인',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              color: Color(0xFF6B7AFF)
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7AFF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
