import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.0.102:8080'; // ⚠️ 맥북 IP

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
}
