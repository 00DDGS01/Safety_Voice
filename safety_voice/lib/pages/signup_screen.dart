// // lib/pages/signup_screen.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nicknameController = TextEditingController();
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _passwordConfirmController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   bool _isLoading = false;

//   Future<void> _handleSignup() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_passwordController.text != _passwordConfirmController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final response = await http.post(
//         Uri.parse('http://10.0.2.2:8000/api/auth/signup/'), // Android 에뮬레이터용

//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'nickname': _nicknameController.text,
//           'username': _usernameController.text,
//           'password': _passwordController.text,
//           'location': _locationController.text,
//           'email': _emailController.text,
//         }),
//       );

//       if (response.statusCode == 201) {
//         if (!mounted) return;
//         Navigator.pushReplacementNamed(context, '/login');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('회원가입이 완료되었습니다.')),
//         );
//       } else {
//         final error = jsonDecode(response.body)['error'];
//         throw Exception(error ?? '회원가입에 실패했습니다.');
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('회원가입'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//       ),
//       body: Form(
//         key: _formKey,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _nicknameController,
//                   decoration: const InputDecoration(
//                     hintText: '닉네임을 입력해주세요',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return '닉네임을 입력해주세요';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _usernameController,
//                   decoration: const InputDecoration(
//                     hintText: '아이디를 입력해주세요',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return '아이디를 입력해주세요';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: const InputDecoration(
//                     hintText: '비밀번호를 입력해주세요',
//                     border: OutlineInputBorder(),
//                   ),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return '비밀번호를 입력해주세요';
//                     }
//                     if (value.length < 8) {
//                       return '비밀번호는 8자 이상이어야 합니다';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _passwordConfirmController,
//                   decoration: const InputDecoration(
//                     hintText: '비밀번호를 한 번 더 입력해주세요',
//                     border: OutlineInputBorder(),
//                   ),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return '비밀번호를 다시 입력해주세요';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _locationController,
//                   decoration: const InputDecoration(
//                     hintText: '거주 지역을 입력해주세요',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return '거주 지역을 입력해주세요';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(
//                     hintText: '이메일을 입력해주세요',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return '이메일을 입력해주세요';
//                     }
//                     if (!value.contains('@')) {
//                       return '올바른 이메일 형식이 아닙니다';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _handleSignup,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF6B7AFF),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text(
//                             '회원가입',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                             ),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _nicknameController.dispose();
//     _usernameController.dispose();
//     _passwordController.dispose();
//     _passwordConfirmController.dispose();
//     _locationController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }
// }

// lib/pages/signup_screen.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:safety_voice/pages/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/auth/signup'), // Spring Boot 서버
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nickname': _nicknameController.text,
          'loginId': _usernameController.text,
          'password': _passwordController.text,
          'location': _locationController.text,
          'email': _emailController.text,
        }),
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 200 && resBody['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resBody['data'] ?? '회원가입 성공')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        final errorMessage =
            resBody['message'] ?? resBody['error'] ?? '회원가입에 실패했습니다.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: const Text('회원가입'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    hintText: '닉네임을 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: '아이디를 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '아이디를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: '비밀번호를 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordConfirmController,
                  decoration: const InputDecoration(
                    hintText: '비밀번호를 한 번 더 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: '거주 지역을 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '거주 지역을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: '이메일을 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
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
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
