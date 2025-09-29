import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CaseFileSelectPage extends StatefulWidget {
  final File sourceFile;
  final List<String>? excludeTitles;

  const CaseFileSelectPage({
    super.key, 
    required this.sourceFile,
    this.excludeTitles
    });

  @override
  State<CaseFileSelectPage> createState() => _CaseFileSelectPageState();
}

class _CaseFileSelectPageState extends State<CaseFileSelectPage> {
  List<String> _titles = [];
  String? _selectedTitle;
  bool _loading = true;
  bool _moving = false;
  String? _error;


  @override
  void initState() {
    super.initState();
    _loadTitles();
  }

  Future<File> _resolveDataJsonFile() async {
    // data.json은 앱 문서 폴더에 있다고 가정 (예: getApplicationDocumentsDirectory)
    final docDir = await getApplicationDocumentsDirectory();
    return File(p.join(docDir.path, 'data.json'));
  }

  Future<void> _loadTitles() async {
    
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dataFile = await _resolveDataJsonFile();
      if (!await dataFile.exists()) {
        throw Exception('data.json을 찾을 수 없습니다: ${dataFile.path}');
      }
      final raw = await dataFile.readAsString();
      final decoded = jsonDecode(raw);

      final titles = <String>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is String) {
            titles.add(item);
          } else if (item is Map && item['title'] is String) {
            titles.add(item['title'] as String);
          }
        }
      } else {
        throw Exception('data.json 형식이 올바르지 않습니다. List 형태여야 합니다.');
      }

      if (titles.isEmpty) {
        throw Exception('data.json에 타이틀이 없습니다.');
      }

      final exclude = (widget.excludeTitles ?? []).map((e) => e.trim()).toSet();
      final filtered = titles.where((t) => !exclude.contains(t.trim())).toList();

      if (filtered.isEmpty) {
        throw Exception('선택 가능한 사건이 없습니다.');
      }

      setState(() {
        _titles = filtered.toSet().toList()..sort();
        _selectedTitle = _titles.first;
        _loading = false;
      });

      setState(() {
        _titles = titles;
        _selectedTitle = titles.first; // 기본 선택 1개
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _moveFileToSelected() async {
    if (_selectedTitle == null) return;
    setState(() {
      _moving = true;
      _error = null;
    });
    try {
      // 대상 폴더: 문서디렉터리/<선택한 타이틀>/
      final docDir = await getApplicationDocumentsDirectory();
      final safeFolderName = _sanitizeFolderName(_selectedTitle!);
      final targetDir = Directory(p.join(docDir.path, safeFolderName));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final src = widget.sourceFile;
      if (!await src.exists()) {
        throw Exception('이동할 원본 파일이 존재하지 않습니다: ${src.path}');
      }

      final newPath = p.join(targetDir.path, p.basename(src.path));
      final finalPath = await _resolveCollision(newPath);

      // 같은 파티션이면 rename, 실패하면 copy→delete 폴백
      File moved;
      try {
        moved = await src.rename(finalPath);
      } catch (_) {
        moved = await src.copy(finalPath);
        await src.delete();
      }

      if (!await moved.exists()) {
        throw Exception('파일 이동에 실패했습니다.');
      }

      // ✅ 여기! 이동 성공 직후 결과 반환
      final movedBytes = await moved.length();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 이동 완료: ${moved.path}')),
      );
      Navigator.pop(context, {
        'title': _selectedTitle!,        // 선택한 사건 제목
        'path': moved.path,              // 최종 파일 경로
        'bytes': movedBytes.toString(),  // 파일 크기(문자열로 보냄)
      });

      setState(() {
        _moving = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _moving = false;
      });
    }
  }


  // 단일 선택 체크박스 UX: 한 개만 true가 되도록 강제
  void _onCheck(String title, bool? checked) {
    if (checked != true) {
      // 체크 해제는 허용하지 않고, 다른 걸 켜는 방식으로만 변경
      return;
    }
    setState(() {
      _selectedTitle = title;
    });
  }

  String _sanitizeFolderName(String input) {
    // 폴더명에 부적합한 문자 제거/치환
    final replaced = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return replaced.isEmpty ? 'untitled' : replaced;
    }

  Future<String> _resolveCollision(String path) async {
    var candidate = path;
    final dir = p.dirname(path);
    final base = p.basenameWithoutExtension(path);
    final ext = p.extension(path);
    var i = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(dir, '$base($i)$ext');
      i++;
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle =
        _selectedTitle == null ? "사건 파일 선택" : "사건: $_selectedTitle";

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // ← 배경색 흰색
      appBar: AppBar(title: Text(appBarTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadTitles)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.audiotrack),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "이동할 녹음 파일: ${p.basename(widget.sourceFile.path)}",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _titles.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final title = _titles[index];
                          final checked = _selectedTitle == title;
                          return CheckboxListTile(
                            title: Text(title),
                            value: checked,
                            onChanged: (v) => _onCheck(title, v),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: _moving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.drive_file_move_outline),
                            label: Text(_moving ? "이동 중..." : "선택한 사건 폴더로 파일 이동"),
                            onPressed: _moving ? null : _moveFileToSelected,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              onPressed: onRetry,
            )
          ],
        ),
      ),
    );
  }
}
