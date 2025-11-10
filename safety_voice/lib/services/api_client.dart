import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://safetyvoice.jp.ngrok.io';

  static Future<http.Response> get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token', // ✅ 토큰 추가
    };

    final url = Uri.parse('$baseUrl$endpoint');
    print('➡️ GET 요청: $url');
    print('🪪 JWT: $token');
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token', // ✅ 토큰 추가
    };

    final url = Uri.parse('$baseUrl$endpoint');
    print('➡️ POST 요청: $url');
    print('🪪 JWT: $token');
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String endpoint, dynamic body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl$endpoint');
    print('➡️ PUT 요청: $url');
    print('🪪 JWT: $token');
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  static Future<void> fetchUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      print('⚠️ JWT 토큰이 없습니다. 로그인 후 다시 시도하세요.');
      return;
    }

    final url = Uri.parse('$baseUrl/api/user/settings');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('➡️ GET 요청 (사용자 설정): $url');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];

        if (data != null) {
          // ✅ 기존 설정 초기화 후 새로 저장
          await prefs.setString('trigger_word', data['triggerWord'] ?? '');
          await prefs.setString(
              'emergency_trigger_word', data['emergencyTriggerWord'] ?? '');
          await prefs.setBool(
              'is_voice_trained', data['isVoiceTrained'] ?? false);
          await prefs.setString('emergency_contacts',
              jsonEncode(data['emergencyContacts'] ?? []));

          print('✅ 사용자 설정 동기화 완료');
        } else {
          print('⚠️ data 필드가 비어 있습니다.');
        }
      } else if (response.statusCode == 403) {
        print('❌ 인증 실패 (JWT 만료)');
      } else {
        print('❌ 서버 오류: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('🚨 네트워크 오류: $e');
    }
  }
}
