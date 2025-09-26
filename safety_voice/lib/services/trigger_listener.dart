import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:safety_voice/pages/stopRecord.dart';

class TriggerListener {
  // ✅ 싱글톤 인스턴스
  static final TriggerListener _instance = TriggerListener._internal();

  factory TriggerListener() => _instance;

  TriggerListener._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isShutDown = false;
  final String trigger = "잠깐 잠깐 잠깐";

  Future<void> init(BuildContext context) async {
    await Permission.microphone.request();

    bool available = await _speech.initialize(
      onStatus: (status) {
        print("📡 STT 상태: $status");

        if (!_isShutDown && (status == 'done' || status == 'notListening') && _isListening) {
          Future.delayed(const Duration(milliseconds: 500), () => _startListening(context));
        }
      },
      onError: (error) {
        print("❌ STT 오류: ${error.errorMsg}");
        if (!_isShutDown && _isListening) {
          Future.delayed(const Duration(seconds: 1), () => _startListening(context));
        }
      },
    );

    if (!available) {
      print("❌ STT 초기화 실패");
      return;
    }

    print("✅ STT 초기화 완료");
    _startListening(context);
  }

  void _startListening(BuildContext context) {
    if (_speech.isListening || _isShutDown) return;

    _speech.listen(
      onResult: (result) {
        final transcript = result.recognizedWords.trim();
        print("🗣️ 인식된 문장: $transcript");

        if (transcript.contains(trigger)) {
          print("🚨 트리거 단어 감지됨!");
          stop();

          Navigator.pushReplacement(
            context,
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
      _speech.cancel(); // ⬅️ stop() 대신 cancel() 사용
      _isListening = false;
      print("🛑 STT 종료됨 (cancel)");
    }
  }

  // ✅ 새로 추가된 pause (stop과 동일 동작)
  void pause() {
    stop();
    print("⏸️ STT 일시정지됨 (pause -> stop)");
  }

  void restart(BuildContext context) {
    if (_isShutDown && !_speech.isListening && !_isListening) {
      print("🔄 STT 재시작됨");
      _isShutDown = false;
      _startListening(context);  // 새로운 context로
    } else {
      print("⚠️ STT 이미 실행 중이거나 재시작 조건 아님");
    }
  }
}
