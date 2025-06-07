import 'dart:io';
import 'package:flutter/material.dart';

class CaseFileSelectPage extends StatelessWidget {
  final File sourceFile;

  const CaseFileSelectPage({super.key, required this.sourceFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("사건 파일 선택")),
      body: Center(
        child: Text("아직 구현되지 않은 페이지입니다."),
      ),
    );
  }
}
