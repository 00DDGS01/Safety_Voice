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
    String? _selectedFolder; // ✅ 드롭다운에서 선택된 폴더 이름을 저장하는 변수
   Future<List<String>> _loadFolderNames() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/created_folders.txt');
  

  if (!await file.exists()) 
  {
    print("X created.txt없음");
    return [];
  }

  final lines = await file.readAsLines();
  final folderNames = <String>{};
  for (var line in lines) {
    folderNames.add(line.trim());
  }
  return folderNames.toList();
}
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
            String duration = await _getAudioDuration(filePath, false); // ✅ 내부 저장소 파일 길이 측정

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
                    fontSize: MediaQuery.of(context).size.width * 0.05,
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
                    color: _currentPlayingFile == file["path"] ? Colors.red : Colors.blue,
                  ),
                ),

                // 2열: 파일명 + 시간
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
                          "시간: ${file["duration"]}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3열: 메뉴 + 용량
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 99.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text("추가", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("사건 파일로 저장"),
                                      content: StatefulBuilder( // ✅ 이거 추가
                                        builder: (context, setStateSB) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FutureBuilder<List<String>>(
                                                future: _loadFolderNames(),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return const CircularProgressIndicator();
                                                  }
                                                  final folderNames = snapshot.data!;
                                                  return DropdownButtonFormField<String>(
                                                    value: _selectedFolder,
                                                    decoration: const InputDecoration(labelText: "폴더 선택"),
                                                    items: folderNames.map((name) {
                                                      return DropdownMenuItem<String>(
                                                        value: name,
                                                        child: Text(name),
                                                      );
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      setStateSB(() { // ✅ 여기선 StatefulBuilder의 setState 사용
                                                        _selectedFolder = value;
                                                      });
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("취소"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            if (_selectedFolder == null || _selectedFolder!.isEmpty) return;

                                            final dir = await getApplicationDocumentsDirectory();
                                            final folderDir = Directory('${dir.path}/$_selectedFolder');
                                            if (!await folderDir.exists()) {
                                              await folderDir.create(recursive: true);
                                            }

                                            final srcFile = File(file['path']);
                                            final fileName = srcFile.path.split('/').last;
                                            final newPath = '${folderDir.path}/$fileName';
                                            await srcFile.copy(newPath);

                                            Navigator.pop(context);
                                          },
                                          child: const Text("저장"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              
                              child: const Text("이동", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteAudioFile(file),
                              child: const Text("삭제", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "용량: ${getFileSize(file["size"])}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(width: double.infinity, height: 1.0, color: const Color(0xFFCACACA)),
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
}