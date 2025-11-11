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
    this.excludeTitles,
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

  // 숨길 폴더명(루트)
  static const String kRootFolderName = '내 폴더';
  bool _isHiddenFolderName(String name) => name.trim() == kRootFolderName;

  @override
  void initState() {
    super.initState();
    _loadTitles();
  }

  Future<File> _resolveDataJsonFile() async {
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

      final exclude = (widget.excludeTitles ?? []).map((e) => e.trim()).toSet();
      final filtered = titles
          .where((t) => t.trim().isNotEmpty)
          .where((t) => !_isHiddenFolderName(t)) // '내 폴더' 숨김
          .where((t) => !exclude.contains(t.trim()))
          .toSet()
          .toList()
        ..sort();

      if (filtered.isEmpty) {
        throw Exception('또 다른 사건 파일이 없습니다.');
      }

      setState(() {
        _titles = filtered;
        _selectedTitle = _titles.first;
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

      final movedBytes = await moved.length();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 이동 완료: ${moved.path}')),
      );
      Navigator.pop(context, {
        'title': _selectedTitle!,
        'path': moved.path,
        'bytes': movedBytes.toString(),
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

  void _onCheck(String title, bool? checked) {
    if (checked != true) return;
    setState(() {
      _selectedTitle = title;
    });
  }

  String _sanitizeFolderName(String input) {
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor: const Color.fromARGB(255, 239, 243, 255),
            centerTitle: true,
            automaticallyImplyLeading: true, // iOS 스와이프 back 허용
            leading: BackButton(
              color: Colors.black,
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            ),
            title: Text(
              "파일 이동",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width * 0.05,
                color: Colors.black,
              ),
            ),
          ),
        ),
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
                            if (_isHiddenFolderName(title)) {
                              return const SizedBox.shrink();
                            }
                            final checked = _selectedTitle == title;
                            return CheckboxListTile(
                              title: Text(title, overflow: TextOverflow.ellipsis),
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
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _moving ? null : _moveFileToSelected,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B73FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: Text(
                                _moving ? '이동 중...' : '선택한 사건 폴더로 파일 이동',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
