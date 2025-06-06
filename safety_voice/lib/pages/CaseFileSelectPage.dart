// case_file_select_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_voice/services/file_helper.dart';

class CaseFileSelectPage extends StatefulWidget {
  final File sourceFile;
  const CaseFileSelectPage({required this.sourceFile, super.key});

  @override
  State<CaseFileSelectPage> createState() => _CaseFileSelectPageState();
}

class _CaseFileSelectPageState extends State<CaseFileSelectPage> {
  late Future<List<String>> caseFoldersFuture;

  @override
  void initState() {
    super.initState();
    caseFoldersFuture = _loadCaseFolders();
  }

  Future<List<String>> _loadCaseFolders() async {
    final dir = await getApplicationDocumentsDirectory();
    final casefilesDir = Directory('${dir.path}/casefiles');
    if (!await casefilesDir.exists()) return [];
    final subdirs = await casefilesDir.list().toList();
    return subdirs
        .whereType<Directory>()
        .map((d) => d.path.split('/').last)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이동할 사건 파일 선택')),
      body: FutureBuilder<List<String>>(
        future: caseFoldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('이동 가능한 사건 파일이 없습니다.'));
          } else {
            final caseFolders = snapshot.data!;
            return ListView.builder(
              itemCount: caseFolders.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(caseFolders[index]),
                  onTap: () async {
                    await moveFileToCaseFolder(
                        widget.sourceFile, caseFolders[index]);
                    Navigator.pop(context); // 이동 후 이전 화면으로
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${caseFolders[index]}로 이동 완료")),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> moveFileToCaseFolder(File file, String folderName) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${dir.path}/casefiles/$folderName');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final newPath = '${targetDir.path}/${file.uri.pathSegments.last}';
    await file.copy(newPath);
  }
}
