import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ListHome extends StatefulWidget {
  const ListHome({super.key});

  @override
  State<ListHome> createState() => _ListHomeState();
}

class _ListHomeState extends State<ListHome> {
  List<String> _caseFolders = [];

  @override
  void initState() {
    super.initState();
    _loadCaseFolders();
  }

  Future<List<String>> getCaseFileFolders() async {
    final dir = await getApplicationDocumentsDirectory();
    final casefilesDir = Directory('${dir.path}/casefiles');
    if (!await casefilesDir.exists()) return [];
    final subdirs = await casefilesDir.list().toList();
    final folderNames = subdirs
        .whereType<Directory>()
        .map((d) => d.path.split(Platform.pathSeparator).last)
        .where((name) => name.contains('사건 파일'))
        .toList();
    return folderNames;
  }

  Future<void> _loadCaseFolders() async {
    final folders = await getCaseFileFolders();
    setState(() {
      _caseFolders = folders;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('y년 M월 d일').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // AppBar 높이를 80으로 설정
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
              icon: Image.asset(
                'assets/images/calendar_gray.png',
                height: 30,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/listhome'),
              icon: Image.asset(
                'assets/images/list.png',
                height: 30,
              ),
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
                  // 각 파일 항목
                  Container(
                    width: double.infinity,
                    height: 99.0,
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/nonamed'),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: const EdgeInsets.only(top: 22.0, left: 15.0),
                          child: const Text(
                            '이름 없는 파일',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 1.0,
                    color: const Color(0xFFCACACA),
                  ),
                  for (final folderName in _caseFolders) ...[
                    Container(
                      width: double.infinity,
                      height: 99.0,
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/casefile'),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin:
                                const EdgeInsets.only(top: 22.0, left: 15.0),
                            child: Text(
                              folderName,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 1.0,
                      color: const Color(0xFFCACACA),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 오른쪽 아래에 오버레이 이미지 버튼
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  isScrollControlled: true, // 창 크기 제어 가능
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20.0),
                    ),
                  ),
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.8, // 창 높이 화면의 80%
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "사건 파일 추가",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            decoration: InputDecoration(
                              labelText: "파일 이름",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            decoration: InputDecoration(
                              labelText: "사건 설명",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // 창 닫기
                              // 추가 동작 처리
                            },
                            child: const Text("추가"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/plus.png', // plus.png 이미지 사용
                width: 60,
                height: 60,
              ),
            ),
          ),
          // 왼쪽 아래에 녹음 버튼 추가
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/stoprecord'),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                padding: const EdgeInsets.all(16.0),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 70, // 하단바 세로 길이를 고정
        child: Material(
          elevation: 10, // 하단바 그림자 효과 추가
          color: const Color.fromARGB(255, 58, 58, 58),
          child: BottomAppBar(
            color: const Color.fromARGB(255, 255, 255, 255), // 하단바 배경색 설정
            shape: const CircularNotchedRectangle(), // 둥근 디자인 추가
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/listhome'),
                  child: Container(
                    child: Image.asset(
                      'assets/images/recordingList.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/safezone'),
                  child: Container(
                    child: Image.asset(
                      'assets/images/wordRecognition.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/setup'),
                  child: Container(
                    child: Image.asset(
                      'assets/images/safeZone.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
