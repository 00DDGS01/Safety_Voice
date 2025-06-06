import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<List<Directory>> getCaseFileFolders() async {
  final dir = await getApplicationDocumentsDirectory();
  final caseDir = Directory('${dir.path}/casefiles');

  if (!await caseDir.exists()) {
    return []; // 폴더 없으면 빈 리스트
  }

  final folders = caseDir
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.contains('사건 파일'))
      .toList();

  return folders;
}
