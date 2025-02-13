import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

class Nonamed extends StatefulWidget {
  const Nonamed({super.key});

  @override
  State<Nonamed> createState() => _NonamedState();
}

class _NonamedState extends State<Nonamed> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingFile;
  List<Map<String, dynamic>> audioFiles = [];

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  // 📌 오디오 길이 가져오기 함수
  Future<String> _getAudioDuration(String filePath, bool isAsset) async {
    try {
      final player = AudioPlayer();

      if (isAsset) {
        await player.setSource(AssetSource(filePath.replaceFirst("assets/", "")));
      } else {
        await player.setSource(DeviceFileSource(filePath)); // ✅ 내부 저장소 파일도 지원
      }

      Duration? duration = await player.getDuration();
      return _formatDuration(duration ?? Duration.zero);
    } catch (e) {
      print("🚨 오디오 길이 가져오기 오류: $e");
      return "00:00";
    }
  }

  // 📌 기존 assets 파일 + 내부 저장소 녹음 파일 불러오기
  Future<void> _loadAudioFiles() async {
    try {
      List<Map<String, dynamic>> files = [];

      // ✅ 1. Assets 파일 추가
      final assetPaths = ["assets/m4a/test.m4a", "assets/m4a/Bok_badara.m4a", "assets/m4a/test11.m4a"];
      for (var path in assetPaths) {
        ByteData data = await rootBundle.load(path);
        String duration = await _getAudioDuration(path, true); // ✅ asset 파일도 길이 측정

        files.add({
          "name": path.split('/').last,
          "path": path,
          "size": data.lengthInBytes,
          "duration": duration,
          "isAsset": true,
        });
      }

      // ✅ 2. 내부 저장소에서 녹음 파일 리스트 불러오기
      final dir = await getApplicationDocumentsDirectory();
      final recordingListFile = File('${dir.path}/recording_list.txt');

      if (await recordingListFile.exists()) {
        List<String> savedFiles = await recordingListFile.readAsLines();
        for (var filePath in savedFiles) {
          final file = File(filePath);
          if (await file.exists()) {
            int fileSize = await file.length();
            String duration = await _getAudioDuration(filePath, false); // ✅ 내부 저장소 파일 길이 측정

            files.add({
              "name": file.path.split('/').last,
              "path": file.path,
              "size": fileSize,
              "duration": duration, // ✅ 길이 정보 업데이트
              "isAsset": false,
            });

            print("📌 추가된 녹음 파일: $filePath, 길이: $duration");
          }
        }
      }

      setState(() {
        audioFiles = files;
      });
    } catch (e) {
      print("🚨 파일 불러오기 오류: $e");
    }
  }

  // 📌 시간 형식 변환 함수
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // 📌 파일 크기 변환 함수
  String getFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(2)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  // 📌 오디오 재생 및 정지 기능
  Future<void> _togglePlayback(String filePath, bool isAsset) async {
    try {
      if (_currentPlayingFile == filePath) {
        await _audioPlayer.stop();
        setState(() => _currentPlayingFile = null);
      } else {
        if (isAsset) {
          await _audioPlayer.play(AssetSource(filePath.replaceFirst("assets/", "")));
        } else {
          await _audioPlayer.play(DeviceFileSource(filePath));
        }
        setState(() => _currentPlayingFile = filePath);
      }
    } catch (e) {
      print('🚨 오디오 재생 오류: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          title: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/listhome'),
            child: Row(
              children: [
                Image.asset('assets/images/back.png', height: 24),
                const SizedBox(width: 8),
                Text(
                  "이름 없는 파일",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width * 0.07,
                  ),
                ),
              ],
            ),
          ),
          automaticallyImplyLeading: false,
        ),
      ),

      // 스크롤 기능
      body: Scrollbar(
        child: ListView.builder(
          itemCount: audioFiles.length,
          itemBuilder: (context, index) {
            return _buildAudioFileContainer(audioFiles[index]);
          },
        ),
      ),
    );
  }


  // 오디오 파일 컨테이너 생성
  Widget _buildAudioFileContainer(Map<String, dynamic> file) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 99.0,
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => _togglePlayback(file["path"], file["isAsset"]),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.only(top: 22.0, left: 15.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      _currentPlayingFile == file["path"]
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      size: 40,
                      color: _currentPlayingFile == file["path"] ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file["name"],
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "크기: ${getFileSize(file["size"])}",
                          style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                        ),
                        Text(
                          "녹음 시간: ${file["duration"]}",
                          style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(width: double.infinity, height: 1.0, color: const Color(0xFFCACACA)),
      ],
    );
  }
}
