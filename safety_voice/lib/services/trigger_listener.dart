// lib/services/trigger_listener.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:safety_voice/pages/stopRecord.dart';
import 'package:safety_voice/main.dart'; // ✅ navigatorKey 가져오기

class TriggerListener {
  // ✅ 싱글톤
  TriggerListener._internal();
  static final TriggerListener instance = TriggerListener._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isShutDown = false;
  final String _trigger = "잠깐 잠깐 잠깐";

  /// STT 초기화 (전역 navigatorKey로 context 없이 사용 가능)
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    await Permission.microphone.request();

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
          Future.delayed(const Duration(seconds: 1),
              () => _startListening(navigatorKey));
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
      onResult: (result) {
        final transcript = result.recognizedWords.trim();
        print("🗣️ 인식된 문장: $transcript");

        if (transcript.contains(_trigger)) {
          print("🚨 트리거 감지됨!");
          stop();

          navigatorKey.currentState?.pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const StopRecord(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
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
}