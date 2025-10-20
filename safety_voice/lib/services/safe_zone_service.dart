import 'dart:convert';
import 'package:safety_voice/services/api_client.dart';
import 'package:http/http.dart' as http;

class SafeZoneService {
  /// 🔹 안전지대 전체 조회
  static Future<List<dynamic>> fetchSafeZones() async {
    try {
      final response = await ApiClient.get('/api/safe-zones');
      print('📡 응답 코드: ${response.statusCode}');
      print('📦 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 안전지대 조회 실패: $e');
      rethrow;
    }
  }

  /// 🔹 안전지대 수정
  static Future<bool> updateSafeZones(Map<String, dynamic> body) async {
    try {
      final response = await ApiClient.post('/api/safe-zones', body);
      print('📡 응답 코드: ${response.statusCode}');
      print('📦 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ 수정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('🚨 안전지대 수정 실패: $e');
      return false;
    }
  }
}
