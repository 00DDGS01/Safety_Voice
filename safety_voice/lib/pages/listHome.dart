import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:path_provider/path_provider.dart';

class ListHome extends StatelessWidget {
  const ListHome({super.key});

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
                                  onTap: () => Navigator.pushNamed(context, '/casefile'),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 22.0, left: 15.0),
                                      child: Text(
                                        item['title'] ?? '제목 없음',
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
                          );
                        }).toList(),
                      );
                    },
                  )
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
