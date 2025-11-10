import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:safety_voice/pages/case_file_select_page.dart';
import 'package:safety_voice/services/gpt_service.dart';
import 'package:safety_voice/services/whisper_service.dart';
import 'dart:typed_data';
import 'package:safety_voice/utils/secrets.dart';
import 'package:safety_voice/services/trigger_listener.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

Future<File> _localDataJsonFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, 'data.json'));
}

Future<List<Map<String, dynamic>>> _readDataJson() async {
  final f = await _localDataJsonFile();
  if (!await f.exists()) return [];
  final raw = await f.readAsString();
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list;
}

Future<void> _writeDataJson(List<Map<String, dynamic>> items) async {
  final f = await _localDataJsonFile();
  final tmp = File('${f.path}.tmp');
  await tmp.writeAsString(jsonEncode(items), flush: true);
  if (await f.exists()) await f.delete();
  await tmp.rename(f.path);
}

int _parseSizeToBytes(String s) {
  final m = RegExp(r'^\s*([\d.]+)\s*(B|KB|MB|GB|TB)\s*$', caseSensitive: false)
      .firstMatch(s.trim());
  if (m == null) return 0;
  final numVal = double.tryParse(m.group(1)!) ?? 0.0;
  final unit = (m.group(2) ?? 'B').toUpperCase();
  const k = 1024.0;
  switch (unit) {
    case 'TB':
      return (numVal * k * k * k * k).round();
    case 'GB':
      return (numVal * k * k * k).round();
    case 'MB':
      return (numVal * k * k).round();
    case 'KB':
      return (numVal * k).round();
    default:
      return numVal.round();
  }
}

String _formatBytes(int bytes) {
  const k = 1024.0;
  if (bytes >= k * k * k * k)
    return '${(bytes / (k * k * k * k)).toStringAsFixed(2)}TB';
  if (bytes >= k * k * k)
    return '${(bytes / (k * k * k)).toStringAsFixed(2)}GB';
  if (bytes >= k * k) return '${(bytes / (k * k)).toStringAsFixed(1)}MB';
  if (bytes >= k) return '${(bytes / k).toStringAsFixed(0)}KB';
  return '${bytes}B';
}

class Nonamed extends StatefulWidget {
  const Nonamed({super.key});

  @override
  State<Nonamed> createState() => _NonamedState();
}

class _NonamedState extends State<Nonamed> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingFile;
  List<Map<String, dynamic>> audioFiles = [];
  bool _changed = false;

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
        await player
            .setSource(AssetSource(filePath.replaceFirst("assets/", "")));
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

  // 📌 내부 저장소 녹음 파일만 불러오기
  Future<void> _loadAudioFiles() async {
    try {
      List<Map<String, dynamic>> files = [];

      // ✅ 내부 저장소에서 녹음 파일 리스트 불러오기
      final dir = await getApplicationDocumentsDirectory();
      final recordingListFile = File('${dir.path}/recording_list.txt');

      if (await recordingListFile.exists()) {
        List<String> savedFiles = await recordingListFile.readAsLines();
        for (var filePath in savedFiles) {
          final file = File(filePath);
          if (await file.exists()) {
            int fileSize = await file.length();
            String duration =
                await _getAudioDuration(filePath, false); // ✅ 내부 저장소 파일 길이 측정

            files.add({
              "name": file.path.split('/').last,
              "path": file.path,
              "size": fileSize,
              "duration": duration,
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
        TriggerListener.instance.resumeListening(); // ✅ 재생 중지 → STT 재시작
        setState(() => _currentPlayingFile = null);
      } else {
        TriggerListener.instance.pauseListening(); // ✅ 재생 시작 → STT 일시 정지
        if (isAsset) {
          await _audioPlayer.play(
            AssetSource(filePath.replaceFirst("assets/", "")),
          );
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 239, 243, 255),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', height: 24),
            onPressed: () {
              Navigator.pop(context, true); // ← 홈으로 true 전달
            },
          ),
          title: Text(
            "이름 없는 파일",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.05,
              color: Colors.black,
            ),
          ),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ▶️ 아이콘 (1열)
                Container(
                  height: 99.0,
                  width: 50,
                  alignment: Alignment.center,
                  child: Icon(
                    _currentPlayingFile == file["path"]
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: 36,
                    color: _currentPlayingFile == file["path"]
                        ? Colors.red
                        : Color.fromARGB(255, 87, 123, 229),
                  ),
                ),

                // 2열: 파일명 + 시간 + 용량
                Expanded(
                  flex: 7,
                  child: Container(
                    height: 99.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file["name"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "시간 : ${file["duration"]}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "용량 : ${getFileSize(file["size"])}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3열: 메뉴 아이콘 버튼 (이동, 수정, 삭제) 및 GPT 요약 버튼
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 99.0,
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final result =
                                    await Navigator.push<Map<String, String>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CaseFileSelectPage(
                                        sourceFile: File(file['path'])),
                                  ),
                                );

                                if (result != null) {
                                  final movedTitle = result['title']!;
                                  final movedPath = result['path']!;
                                  final movedBytes =
                                      int.tryParse(result['bytes'] ?? '0') ?? 0;

                                  // 1) data.json 업데이트
                                  final list = await _readDataJson();
                                  final idx = list.indexWhere(
                                      (e) => (e['title'] ?? '') == movedTitle);
                                  if (idx >= 0) {
                                    final item =
                                        Map<String, dynamic>.from(list[idx]);
                                    final oldCount =
                                        (item['count'] as num? ?? 0).toInt();
                                    final oldSizeBytes = _parseSizeToBytes(
                                        (item['size'] as String? ?? '0B'));
                                    final newBytesTotal =
                                        oldSizeBytes + movedBytes;

                                    item['count'] = oldCount + 1;
                                    item['recent'] = DateFormat('yyyy-MM-dd')
                                        .format(DateTime.now());
                                    item['size'] = _formatBytes(newBytesTotal);

                                    list[idx] = item;
                                    await _writeDataJson(list);
                                  }

                                  // 2) recording_list.txt에서도 제거
                                  final dir =
                                      await getApplicationDocumentsDirectory();
                                  final listFile =
                                      File('${dir.path}/recording_list.txt');
                                  if (await listFile.exists()) {
                                    final lines = await listFile.readAsLines();
                                    lines.remove(file['path']);
                                    await listFile
                                        .writeAsString(lines.join('\n'));
                                  }

                                  // 3) Nonamed 리스트에서 제거 + 스낵바
                                  if (!mounted) return;
                                  setState(() {
                                    audioFiles.remove(file);
                                    if (_currentPlayingFile == file["path"])
                                      _currentPlayingFile = null;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '‘$movedTitle’로 이동: ${p.basename(movedPath)}')),
                                  );
                                }
                              },
                              child: Image.asset('assets/images/transfer.png',
                                  width: 24, height: 24),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: () {
                                // 수정 기능 구현 필요 시 여기에 추가
                              },
                              child: Image.asset('assets/images/modify.png',
                                  width: 24, height: 24),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: () => _deleteAudioFile(file),
                              child: Image.asset('assets/images/delete.png',
                                  width: 24, height: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _summarizeWithGPT(file),
                          child: const Text(
                            "GPT로 요약하기",
                            style: TextStyle(
                                fontSize: 10,
                                color: Color.fromARGB(255, 87, 123, 229)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
            width: double.infinity,
            height: 1.0,
            color: const Color(0xFFCACACA)),
      ],
    );
  }

  Future<void> _deleteAudioFile(Map<String, dynamic> file) async {
    try {
      final audioFile = File(file["path"]);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      // Update the recording list file
      final dir = await getApplicationDocumentsDirectory();
      final recordingListFile = File('${dir.path}/recording_list.txt');
      if (await recordingListFile.exists()) {
        List<String> updatedList = await recordingListFile.readAsLines();
        updatedList.remove(file["path"]);
        await recordingListFile.writeAsString(updatedList.join('\n'));
      }

      // Refresh UI
      setState(() {
        audioFiles.remove(file);
        if (_currentPlayingFile == file["path"]) {
          _currentPlayingFile = null;
        }
      });
    } catch (e) {
      print("🚨 삭제 중 오류 발생: $e");
    }
  }

  Future<void> _summarizeWithGPT(Map<String, dynamic> file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 240, 244, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '요약 중...',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final transcript = await transcribeWithWhisper(File(file['path']));
      final summary = await summarizeWithGPT(transcript);

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Color.fromARGB(255, 240, 244, 255),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            '요약 결과',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color.fromARGB(218, 255, 240, 240),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            '오류 발생',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}
