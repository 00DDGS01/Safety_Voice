import 'package:flutter/material.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:permission_handler/permission_handler.dart';

class PorcupineLogger {
  Porcupine? _porcupine;

  Future<void> initPorcupine() async {
    const String accessKey = "CCebtKz+LHM++8MHHb1KrvAg7gO+tq6LL7sRgng64hSqf4TPCqS80g==";
    const List<String> keywordPaths = ["assets/잠깐_ko_android_v3_0_0.ppn"]; // ✅ PPN 파일 리스트

    // 🔹 마이크 권한 요청
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print("🚨 마이크 권한이 필요합니다!");
      return;
    }

    try {
      // ✅ Porcupine 초기화
      _porcupine = await Porcupine.fromKeywordPaths(
        accessKey,
        keywordPaths, // ✅ 올바른 인자 전달
      );

      // ✅ 감지 이벤트 설정
      _porcupine?.setDetectionCallback((index) {
        print("🗣️ 감지됨: 잠깐 - ${DateTime.now()}");
      });

      print("🎤 Porcupine 실행 중...");
    } catch (e) {
      print("🚨 Porcupine 초기화 오류: $e");
    }
  }

  void dispose() {
    _porcupine?.dispose();
  }
}
