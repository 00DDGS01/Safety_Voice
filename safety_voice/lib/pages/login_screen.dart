import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  // Future<void> _login() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //   });

  //   final String username = _usernameController.text.trim();
  //   final String password = _passwordController.text.trim();

  //   if (username.isEmpty || password.isEmpty) {
  //     setState(() {
  //       _errorMessage = '아이디와 비밀번호를 입력하세요.';
  //       _isLoading = false;
  //     });
  //     return;
  //   }

  //   final Uri url = Uri.parse('http://10.0.2.2:8000/api/auth/login/');
  //   final response = await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({'username': username, 'password': password}),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     final token = data['token'];

  //     // 토큰 저장
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('token', token);

  //     // 로그인 성공 시 이동
  //     if (mounted) {
  //       Navigator.pushReplacementNamed(context, '/calendarhome');
  //     }
  //   } else {
  //     final data = jsonDecode(response.body);
  //     setState(() {
  //       _errorMessage = '아이디/비밀번호가 틀렸습니다.';
  //     });
  //   }

  //   setState(() {
  //     _isLoading = false;
  //   });
  // }
  
  Future<void> _login() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  // 아이디와 비밀번호 확인 없이 바로 로그인 성공 처리
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', 'dummy_token'); // 더미 토큰 저장

  // 로그인 버튼을 누르면 바로 다음 화면으로 이동
  if (mounted) {
    Navigator.pushReplacementNamed(context, '/calendarhome');
  }

  setState(() {
    _isLoading = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('로그인'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 150),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: '아이디를 입력해주세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                hintText: '비밀번호를 입력해주세요',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(

                onPressed: _isLoading ? null : _login,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7AFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '로그인',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
