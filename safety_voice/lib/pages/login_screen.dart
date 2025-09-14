import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:safety_voice/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_checkFormValidity);
    _passwordController.addListener(_checkFormValidity);
  }

  void _checkFormValidity() {
    setState(() {
      _isFormValid = _usernameController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '아이디와 비밀번호를 입력하세요.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'loginId': username, //loginId 필드로 전송
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // JWT 토큰 저장 (shared_preferences 사용)
        final token = data['data']['token'];

        // SharedPreferences에 JWT 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        print("로그인 성공, JWT : $token");

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Home(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['message'] ?? '로그인 실패';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '서버 연결 오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF), // 연보라색 배경
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 120),

                // 로그인 타이틀
                const Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 60),

                // 아이디 라벨
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '아이디',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 아이디 입력 필드
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '아이디를 입력해주세요',
                      hintStyle: TextStyle(
                        color: Color(0xFFA9BEFA), // 연한 파란색
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 비밀번호 라벨
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '비밀번호',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 비밀번호 입력 필드
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '비밀번호를 입력해주세요',
                      hintStyle: TextStyle(
                        color: Color(0xFFA9BEFA), // 연한 파란색
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 아이디 찾기 | 비밀번호 찾기 버튼들 (우측 정렬)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // 아이디 찾기 기능
                          print('아이디 찾기 클릭');
                        },
                        child: const Text(
                          '아이디 찾기',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // 비밀번호 찾기 기능
                          print('비밀번호 찾기 클릭');
                        },
                        child: const Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 로그인 버튼
                // Container(
                //   width: double.infinity,
                //   height: 50,
                //   child: ElevatedButton(
                //     onPressed: _isFormValid ? _login : null,
                //     // onPressed: () => Navigator.pushReplacementNamed(context, '/calenda'),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: _isFormValid
                //           ? const Color(0xFF577BE5) // 파란색 (입력 완료시)
                //           : Colors.grey[400], // 회색 (기본)
                //       foregroundColor: Colors.white,
                //       elevation: 0,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //       disabledBackgroundColor: Colors.grey[300],
                //     ),
                //     child: _isLoading
                //         ? const SizedBox(
                //             width: 20,
                //             height: 20,
                //             child: CircularProgressIndicator(
                //               color: Colors.white,
                //               strokeWidth: 2,
                //             ),
                //           )
                //         : const Text(
                //             '로그인',
                //             style: TextStyle(
                //               fontSize: 16,
                //               fontWeight: FontWeight.w500,
                //             ),
                //           ),
                //   ),
                // ),

                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const Home(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF577BE5), // 파란색
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 20),

                // 회원가입 텍스트
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    children: [
                      TextSpan(text: '계정이 없으신가요? '),
                      TextSpan(
                        text: '회원가입하기',
                        style: TextStyle(
                          color: Color(0xFF577BE5), // 파란색
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),

                // 에러 메시지
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
