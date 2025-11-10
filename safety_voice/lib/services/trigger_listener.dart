import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:safety_voice/pages/stopRecord.dart';
import 'package:safety_voice/main.dart'; // ✅ navigatorKey 가져오기

class TriggerListener {
  // ✅ 싱글톤
  TriggerListener._internal();
  static final TriggerListener instance = TriggerListener._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isShutDown = false;

  late String _triggerWord;
  late String _emergencyTriggerWord;

  /// STT 초기화 (전역 navigatorKey로 context 없이 사용 가능)
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    await Permission.microphone.request();
    await Permission.location.request();

    final prefs = await SharedPreferences.getInstance();
    _triggerWord = prefs.getString('trigger_word') ?? "잠깐 잠깐 잠깐";
    _emergencyTriggerWord =
        prefs.getString('emergency_trigger_word') ?? "도와주세요";
    print("📡 prefs keys: ${prefs.getKeys()}");

    print("🎯 현재 트리거 단어: $_triggerWord");
    print("🚨 비상 트리거 단어: $_emergencyTriggerWord");

    bool available = await _speech.initialize(
      onStatus: (status) {
        print("📡 STT 상태: $status");
        if (!_isShutDown &&
            (status == 'done' || status == 'notListening') &&
            _isListening) {
          Future.delayed(const Duration(milliseconds: 500),
              () => _startListening(navigatorKey));
        }
      },
      onError: (error) {
        print("❌ STT 오류: ${error.errorMsg}");
        if (!_isShutDown && _isListening) {
          Future.delayed(
              const Duration(seconds: 1), () => _startListening(navigatorKey));
        }
      },
    );

    if (!available) {
      print("🚨 STT 초기화 실패");
      return;
    }

    print("✅ STT 초기화 완료");
    _startListening(navigatorKey);
  }

  void _startListening(GlobalKey<NavigatorState> navigatorKey) {
    if (_speech.isListening || _isShutDown) return;

    _speech.listen(
      onResult: (result) async {
        final transcript = result.recognizedWords.trim();
        print("🗣️ 인식된 문장: $transcript");

        if (transcript.contains(_triggerWord)) {
          print("🚨 트리거 감지됨! ($_triggerWord)");
          stop();

          navigatorKey.currentState?.pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const StopRecord(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }

        // 비상 트리거 담지 -> api/sms/emergency 호출
        else if (transcript.contains(_emergencyTriggerWord)) {
          print("🚨 비상 트리거 감지됨 ($_emergencyTriggerWord)");
          stop();
          await _sendEmergencySms();

          Future.delayed(const Duration(seconds: 1), () {
            print("🔄 비상 문자 전송 완료 — STT 자동 재시작");
            _isShutDown = false;
            _startListening(navigatorKey);
          });
        }
      },
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 600),
      localeId: 'ko_KR',
      cancelOnError: false,
      partialResults: true,
    );

    _isListening = true;
  }

  Future<void> _sendEmergencySms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        print("❌ JWT 토큰 없음 — 로그인 필요");
        return;
      }

      // ✅ 현재 GPS 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final url =
          Uri.parse("https://safetyvoice.jp.ngrok.io/api/sms/emergency");

      final body = jsonEncode({
        "latitude": position.latitude,
        "longitude": position.longitude,
      });

      print("📍 현재 위치: lat=${position.latitude}, lon=${position.longitude}");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=utf-8",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print("✅ 비상 문자 발송 성공: ${data['message']}");
      } else {
        print("❌ 비상 문자 발송 실패 (${response.statusCode})");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("⚠️ 비상 문자 전송 중 오류: $e");
    }
  }

  void stop() {
    if (_isListening) {
      _isShutDown = true;
      _speech.cancel();
      _isListening = false;
      print("🛑 STT 종료됨 (cancel)");
    }
  }

  void pauseListening() {
    stop();
    print("⏸️ STT 일시정지됨");
  }

  void resumeListening() {
    if (_isShutDown && !_speech.isListening && !_isListening) {
      _isShutDown = false;
      print("🔄 STT 재시작됨");
      _startListening(navigatorKey);
    } else {
      print("⚠️ STT 재시작 조건 아님");
    }
  }

  // ✅ 안전지대용: STT / 마이크 제어
  void stopListening() {
    print("🎙️ [TriggerListener] 안전지대 진입 → STT 정지");
    pauseListening(); // 기존 일시정지 함수 호출
  }

  void startListening() {
    print("🎙️ [TriggerListener] 안전지대 벗어남 → STT 재시작");
    resumeListening(); // 기존 재시작 함수 호출
  }

  Future<void> refreshWords() async {
    final prefs = await SharedPreferences.getInstance();
    _triggerWord = prefs.getString('trigger_word') ?? "잠깐 잠깐 잠깐";
    _emergencyTriggerWord =
        prefs.getString('emergency_trigger_word') ?? "도와주세요";

    print("🔄 트리거 단어 갱신 완료:");
    print("🎯 새 트리거 단어: $_triggerWord");
    print("🚨 새 비상 트리거 단어: $_emergencyTriggerWord");
  }
}
