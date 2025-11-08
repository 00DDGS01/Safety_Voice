import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safety_voice/pages/nonamed.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:safety_voice/services/trigger_listener.dart'; // ✅ TriggerListener 임포트

class StopRecord extends StatefulWidget {
  const StopRecord({super.key});

  @override
  State<StopRecord> createState() => _StopRecordState();
}

class _StopRecordState extends State<StopRecord> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _initRecorder().then((_) {
      _startRecording();
    });
  }

  Future<void> _initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
      await _recorder.openRecorder();
      _isRecorderInitialized = true;
    } catch (e) {
      print('🚨 Error initializing recorder: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!_isRecorderInitialized)
        throw Exception('Recorder is not initialized');
      final dir = await getApplicationDocumentsDirectory();
      _filePath =
          '${dir.path}/${DateFormat('yyyyMMddHHmm').format(DateTime.now())}.mp4';

      await _recorder.startRecorder(
        toFile: _filePath,
        codec: Codec.aacMP4,
      );

      print("🎤 녹음 시작됨: $_filePath");
      setState(() => _isRecording = true);
    } catch (e) {
      print('🚨 Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() => _isRecording = false);

      if (_filePath != null) {
        await _saveRecordingPath(_filePath!);
      }
    } catch (e) {
      print('🚨 Error stopping recording: $e');
    }
  }

  Future<void> _saveRecordingPath(String filePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final recordingListFile = File('${dir.path}/recording_list.txt');

      await recordingListFile.writeAsString('$filePath\n',
          mode: FileMode.append);
      print("✅ 녹음 파일 저장됨: $filePath");
    } catch (e) {
      print("🚨 녹음 파일 저장 오류: $e");
    }
  }

  @override
  void dispose() {
    if (_recorder.isRecording) {
      _recorder.stopRecorder();
    }
    _recorder.closeRecorder();

    // ✅ 녹음 종료 후 STT 재시작
    TriggerListener.instance.resumeListening();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF), // 연한 배경
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 마이크 + glow 효과 (녹음 중일 때만)
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.4),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ]
                    : [],
                color: _isRecording ? Colors.red : Colors.grey,
              ),
              child: const Center(
                child: Icon(Icons.mic, color: Colors.white, size: 60),
              ),
            ),
            const SizedBox(height: 40),

          // 녹음 상태 텍스트
          SizedBox(
          child: Center(
            child: _isRecording
                ? const Text(
                    '녹음을 중지하시겠습니까?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 50),
          // 버튼 2개 (토글 버튼 + 뒤로가기)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔄 녹음 시작 / 중지 버튼
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording
                        ? Colors.white
                        : const Color(0xFF5C7CFA),
                    foregroundColor: _isRecording
                        ? const Color(0xFF5C7CFA)
                        : Colors.white,
                    side: _isRecording
                        ? const BorderSide(color: Color(0xFF5C7CFA))
                        : null,
                    minimumSize: const Size(140, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_isRecording ? '녹음 중지' : '녹음 시작'),
                ),
                const SizedBox(width: 16),

                // ⬅ 뒤로가기 버튼
                ElevatedButton(
                  onPressed: () {
                    TriggerListener.instance.resumeListening();
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const Nonamed(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('뒤로가기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
