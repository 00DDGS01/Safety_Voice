import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CaseFile extends StatefulWidget {
  const CaseFile({super.key});

  @override
  _CaseFileState createState() => _CaseFileState();
}

class _CaseFileState extends State<CaseFile> {
  bool _isExpanded = false; // 세부사항 표시 여부
  List<File> caseFiles = [];

  Future<void> moveFileToCaseFileDirectory(File sourceFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final caseFileDir = Directory('${dir.path}/casefiles');
    if (!await caseFileDir.exists()) {
      await caseFileDir.create(recursive: true);
    }

    final filename = sourceFile.uri.pathSegments.last;
    final newPath = '${caseFileDir.path}/$filename';
    final newFile = await sourceFile.copy(newPath);

    print('✅ 사건파일 디렉토리 경로 : ${caseFileDir.path}');
    print('✅ 이동 완료 : $newPath');
  }

  Future<void> loadCaseFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final caseFileDir = Directory('${dir.path}/casefiles');
    if (await caseFileDir.exists()) {
      final files = caseFileDir.listSync().whereType<File>().where((file) {
        final ext = file.path.split('.').last.toLowerCase();
        return ['aac', 'wav', 'mp3'].contains(ext);
      }).toList();
      setState(() {
        caseFiles = files;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadCaseFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // AppBar 높이를 80으로 설정
        child: AppBar(
          backgroundColor: Colors.white,
          title: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/listhome'),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/back.png', // back.png 이미지
                  height: 24, // 이미지 높이
                ),
                const SizedBox(width: 8), // 이미지와 텍스트 사이 간격
                Text(
                  "사건 파일 1",
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
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            // "사건 설명" + 토글 버튼 + 수정 버튼
            SizedBox(
              height: 40.0, // 빈 상자 높이
              width: MediaQuery.of(context).size.width * 0.95, // 가로폭 85%
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 토글 버튼 + "사건 설명"
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded; // 토글 상태 변경
                          });
                        },
                        icon: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_down // 세부사항이 보이면 아래 방향
                              : Icons.keyboard_arrow_right, // 세부사항이 숨겨지면 오른쪽 방향
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const Text(
                        '사건 설명',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // 오른쪽: 수정 버튼
                  TextButton(
                    onPressed: () {
                      // 수정 버튼 동작
                    },
                    child: const Text(
                      '수정',
                      style: TextStyle(
                          fontSize: 16.0, color: Color(0xFF787878) // 텍스트 색상
                          ),
                    ),
                  ),
                ],
              ),
            ),
            // 세부사항 표시
            if (_isExpanded)
              Container(
                width: MediaQuery.of(context).size.width * 0.95, // 가로폭 85%
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(top: 4.0), // 상단 여백
                child: const Text(
                  '클라이언트와 계약할 때 작성하지 않은 것을 요구하거나 구두계약을 이행하지 않을 때가 있다. 이로 인해 상사에게 언어폭력에 시달리고 있다. 따라서 구두계약 시 증거 자료로써 녹음을 해두고, 상사에게 부당한 대우를 받거나 언어폭력을 당할 때 상사가 눈치채지 못하게 증거자료를 모으려고 한다.',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                ),
              ),
            const Divider(color: Color(0xFFCACACA), thickness: 1.0), // 구분선
            // 추가 내용 (빈 상자들)
            Container(
              width: double.infinity,
              height: 99.0, // 빈 상자 높이
              color: Colors.transparent, // 상자 투명
            ),
            Container(
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: const Color(0xFFCACACA), // 실선 색상
            ),
            Container(
              width: double.infinity,
              height: 99.0, // 빈 상자 높이
              color: Colors.transparent, // 상자 투명
            ),
            Container(
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: const Color(0xFFCACACA), // 실선 색상
            ),
            Container(
              width: double.infinity,
              height: 99.0, // 빈 상자 높이
              color: Colors.transparent, // 상자 투명
            ),
            Container(
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: const Color(0xFFCACACA), // 실선 색상
            ),
            Expanded(
              child: ListView.builder(
                itemCount: caseFiles.length,
                itemBuilder: (context, index) {
                  final file = caseFiles[index];
                  final filename = file.uri.pathSegments.last;
                  return ListTile(
                    leading: const Icon(Icons.audiotrack),
                    title: Text(filename),
                    subtitle: Text(file.path),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
