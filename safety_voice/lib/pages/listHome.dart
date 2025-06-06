import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_voice/pages/caseFile.dart';

class ListHome extends StatefulWidget {
  const ListHome({super.key});

  @override
  State<ListHome> createState() => _ListHomeState();
}

class _ListHomeState extends State<ListHome> {
  Future<void> _createCaseFolder(String title, String desc) async {
    final dir = await getApplicationDocumentsDirectory();
    final folderPath = '${dir.path}/$title';

    final newDir = Directory(folderPath);
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }

    final file = File('${dir.path}/promoted_files.txt');
    final newEntry = '$folderPath###$title###$desc\n';
    await file.writeAsString(newEntry, mode: FileMode.append);

    setState(() {}); // 리로드해서 새로운 폴더 보이게
  }

  Future<void> _deleteCaseFolder(String path) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/promoted_files.txt');

  if (!await file.exists()) return;

  // promoted_files.txt에서 해당 path 줄 제거
  final lines = await file.readAsLines();
  final updatedLines = lines.where((line) => !line.startsWith(path)).toList();
  await file.writeAsString(updatedLines.join('\n'));

  // 실제 폴더도 삭제
  final folder = Directory(path);
  if (await folder.exists()) {
    await folder.delete(recursive: true);
  }

  setState(() {}); // UI 갱신
}

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('y년 M월 d일').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            currentDate,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.05,
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/calendarhome'),
              icon: Image.asset('assets/images/calendar_gray.png', height: 30),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/listhome'),
              icon: Image.asset('assets/images/list.png', height: 30),
            ),
            Container(width: 10),
          ],
        ),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 99.0,
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/nonamed'),
                      child: Container(
                        margin: const EdgeInsets.only(top: 22.0, left: 15.0),
                        child: const Text(
                          '이름 없는 파일',
                          style: TextStyle(color: Colors.black, fontSize: 20.0),
                        ),
                      ),
                    ),
                  ),
                  Container(width: double.infinity, height: 1.0, color: const Color(0xFFCACACA)),
                  FutureBuilder<List<Map<String, String>>>(
                    future: _loadPromotedFiles(),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      return Column(
                        children: items.map((item) {
                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 99.0,
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CaseFile(
                                          title: item['title'] ?? '제목 없음',
                                          description: item['desc'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 22.0, left: 15.0),
                                        child: Text(
                                          item['title'] ?? '제목 없음',
                                          style: const TextStyle(color: Colors.black, fontSize: 20.0),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _deleteCaseFolder(item['path'] ?? '');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(width: double.infinity, height: 1.0, color: const Color(0xFFCACACA)),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // 플러스 버튼 (폴더 생성)
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: GestureDetector(
              onTap: () {
                final folderNameController = TextEditingController();
                final folderDescController = TextEditingController();
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                  ),
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.8,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("사건 폴더 추가", style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: folderNameController,
                            decoration: InputDecoration(
                              labelText: "폴더 이름",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: folderDescController,
                            decoration: InputDecoration(
                              labelText: "사건 설명",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () async {
                              final title = folderNameController.text.trim();
                              final desc = folderDescController.text.trim();
                              if (title.isNotEmpty) {
                                await _createCaseFolder(title, desc);
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text("추가"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Image.asset('assets/images/plus.png', width: 60, height: 60),
            ),
          ),
          // 왼쪽 아래 녹음 버튼
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/stoprecord'),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                padding: const EdgeInsets.all(16.0),
                child: const Icon(Icons.mic, color: Colors.white, size: 30.0),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 70,
        child: Material(
          elevation: 10,
          color: const Color.fromARGB(255, 58, 58, 58),
          child: BottomAppBar(
            color: Colors.white,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/listhome'),
                  child: Image.asset('assets/images/recordingList.png', fit: BoxFit.contain),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/safezone'),
                  child: Image.asset('assets/images/wordRecognition.png', fit: BoxFit.contain),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/setup'),
                  child: Image.asset('assets/images/safeZone.png', fit: BoxFit.contain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<List<Map<String, String>>> _loadPromotedFiles() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/promoted_files.txt');

  if (!await file.exists()) return [];

  final lines = await file.readAsLines();
  return lines.map((line) {
    final parts = line.split('###');
    return {
      'path': parts[0],
      'title': parts.length > 1 ? parts[1] : '제목 없음',
      'desc': parts.length > 2 ? parts[2] : '',
    };
  }).toList();
}

