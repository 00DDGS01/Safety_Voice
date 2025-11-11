import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert'; // data.json 읽기/쓰기
import 'package:safety_voice/pages/case_file_select_page.dart'; // 이동 페이지
import 'package:safety_voice/services/gpt_service.dart'; // GPT 요약
import 'package:safety_voice/services/whisper_service.dart'; // Whisper STT
import 'package:intl/intl.dart';

class CaseFile extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;

  /// (선택) 제목 중복 검사 콜백. 새 제목이 기존과 다를 때만 호출됨.
  final bool Function(String newTitle)? isTitleDuplicate;

  const CaseFile({
    super.key,
    required this.data,
    required this.onUpdate,
    this.isTitleDuplicate,
  });

  @override
  _CaseFileState createState() => _CaseFileState();
}

class _CaseFileState extends State<CaseFile> {
  bool _isExpanded = false;

  final _player = AudioPlayer();
  List<Map<String, dynamic>> _caseFiles = [];
  String? _playing;

  late String title;
  late String description;
  late Color badgeColor; // 배경색
  late Color textColor; // 텍스트색

  @override
  void initState() {
    super.initState();
    title = (widget.data['title'] ?? '') as String;
    description = (widget.data['description'] ?? '') as String;
    badgeColor = _hexToColor(widget.data['color'] ?? '#E7F0FE');
    textColor = _hexToColor(widget.data['textColor'] ?? '#1A73E8');
    _loadCaseFiles();
  }

  // ===== Helpers =====
  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// 선택된 색에 "검정 비율을 섞은" 더 진한 색 (텍스트용)
  Color _mixWithBlack(Color base, [double t = 0.6]) {
    final r = (base.red * (1 - t)).round();
    final g = (base.green * (1 - t)).round();
    final b = (base.blue * (1 - t)).round();
    return Color.fromARGB(255, r, g, b);
  }

  void _showSheetSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openEditModal() {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: description);

    final preset = <Color>[
      const Color(0xFFFDEDED), // 빨강 라이트
      const Color(0xFFEBF8ED), // 초록 라이트
      const Color(0xFFE7F0FE), // 파랑 라이트
      const Color(0xFFFFF4E0), // 주황 라이트
      const Color(0xFFEFEFEF), // 회색 라이트
    ];
    Color selected = badgeColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // 키보드 높이에 맞춰 시트 안쪽 패딩을 부드럽게 변경
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: FractionallySizedBox(
            heightFactor: 0.6, // Home과 동일: 화면의 60%
            child: SafeArea(
              top: false, // 상단만 둥근 모서리 보여주려고 top은 false
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 12, bottom: 16),
                // ✅ 스크롤 가능하게 해서 키보드가 올라와도 영역이 줄어들 때 자연스럽게 스크롤
                child: StatefulBuilder(
                  builder: (ctx, setSheet) {
                    Widget rowField(String label, Widget trailing) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 72,
                                child: Text(label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: trailing),
                            ],
                          ),
                        );

                    return SingleChildScrollView(
                      // 키보드가 올라오면 이 부분이 스크롤되어 컨트롤들이 가려지지 않음
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "사건 파일 수정",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // 제목
                          rowField(
                            '제목',
                            TextField(
                              controller: titleCtrl,
                              decoration: const InputDecoration(
                                hintText: '제목 입력',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),

                          // 설명
                          rowField(
                            '설명',
                            TextField(
                              controller: descCtrl,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              decoration: const InputDecoration(
                                hintText: '간단한 설명',
                                border: OutlineInputBorder(),
                                isDense: true,
                                alignLabelWithHint: true,
                              ),
                            ),
                          ),

                          // 색상
                          rowField(
                            '색상',
                            Wrap(
                              spacing: 10,
                              children: [
                                for (final c in preset)
                                  GestureDetector(
                                    onTap: () => setSheet(() => selected = c),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: c == selected
                                              ? Colors.black
                                              : Colors.black26,
                                          width: c == selected ? 2 : 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    foregroundColor: Colors.black87,
                                    overlayColor: Colors.black12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('취소',
                                      style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    final newTitle = titleCtrl.text.trim();
                                    final newDesc = descCtrl.text.trim();

                                    if (newTitle.isEmpty) {
                                      _showSheetSnack(ctx, '제목을 입력하세요');
                                      return;
                                    }
                                    if (newTitle != title &&
                                        (widget.isTitleDuplicate
                                                ?.call(newTitle) ??
                                            false)) {
                                      _showSheetSnack(ctx, '이미 존재하는 파일 이름입니다');
                                      return;
                                    }

                                    final newBadge = selected;
                                    final newText =
                                        _mixWithBlack(newBadge, 0.6);

                                    setState(() {
                                      title = newTitle;
                                      description = newDesc;
                                      badgeColor = newBadge;
                                      textColor = newText;
                                    });

                                    final updated =
                                        Map<String, dynamic>.from(widget.data)
                                          ..['title'] = newTitle
                                          ..['description'] = newDesc
                                          ..['color'] = _colorToHex(newBadge)
                                          ..['textColor'] =
                                              _colorToHex(newText);

                                    widget.onUpdate(updated);

                                    Navigator.pop(ctx);
                                    _showSheetSnack(context, '사건 파일이 수정되었습니다');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    foregroundColor: Colors.black87,
                                    overlayColor: Colors.black12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('저장',
                                      style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<Directory> _caseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, title));
  }

  Future<void> _loadCaseFiles() async {
    try {
      final dir = await _caseDir();
      final list = <Map<String, dynamic>>[];
      if (await dir.exists()) {
        await for (final ent
            in dir.list(recursive: false, followLinks: false)) {
          if (ent is File && _isAudio(ent.path)) {
            final bytes = await ent.length();
            list.add({
              'name': p.basename(ent.path),
              'path': ent.path,
              'bytes': bytes,
            });
          }
        }
        list.sort((a, b) => a['name'].compareTo(b['name']));
      }
      if (mounted) setState(() => _caseFiles = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 목록을 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  bool _isAudio(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.mp4', '.m4a', '.aac', '.wav', '.mp3', '.ogg'].contains(ext);
  }

  String _fmtSize(int bytes) {
    const k = 1024.0;
    if (bytes >= k * k * k)
      return '${(bytes / (k * k * k)).toStringAsFixed(2)}GB';
    if (bytes >= k * k) return '${(bytes / (k * k)).toStringAsFixed(1)}MB';
    if (bytes >= k) return '${(bytes / k).toStringAsFixed(0)}KB';
    return '${bytes}B';
  }

  Future<File> _localDataJsonFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'data.json'));
  }

  Future<List<Map<String, dynamic>>> _readDataJson() async {
    final f = await _localDataJsonFile();
    if (!await f.exists()) return [];
    final raw = await f.readAsString();
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> _writeDataJson(List<Map<String, dynamic>> items) async {
    final f = await _localDataJsonFile();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(items), flush: true);
    if (await f.exists()) await f.delete();
    await tmp.rename(f.path);
  }

  int _parseSizeToBytes(String s) {
    final m =
        RegExp(r'^\s*([\d.]+)\s*(B|KB|MB|GB|TB)\s*$', caseSensitive: false)
            .firstMatch((s.isEmpty ? '0B' : s).trim());
    if (m == null) return 0;
    final numVal = double.tryParse(m.group(1)!) ?? 0.0;
    final unit = (m.group(2) ?? 'B').toUpperCase();
    const k = 1024.0;
    switch (unit) {
      case 'TB':
        return (numVal * k * k * k * k).round();
      case 'GB':
        return (numVal * k * k * k).round();
      case 'MB':
        return (numVal * k * k).round();
      case 'KB':
        return (numVal * k).round();
      default:
        return numVal.round();
    }
  }

  String _formatBytes(int bytes) {
    const k = 1024.0;
    if (bytes >= k * k * k * k)
      return '${(bytes / (k * k * k * k)).toStringAsFixed(2)}TB';
    if (bytes >= k * k * k)
      return '${(bytes / (k * k * k)).toStringAsFixed(2)}GB';
    if (bytes >= k * k) return '${(bytes / (k * k)).toStringAsFixed(1)}MB';
    if (bytes >= k) return '${(bytes / k).toStringAsFixed(0)}KB';
    return '${bytes}B';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 239, 243, 255),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', height: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.05,
              color: Colors.black,
            ),
          ),
          actions: [
            // 우측 끝 ⋮ 아이콘으로 수정 모달 열기 (Home과 통일)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: _openEditModal,
              tooltip: '수정',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40.0,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.black,
                  ),
                ),
                const Text('사건 설명',
                    style: TextStyle(fontSize: 18, color: Colors.black)),
              ],
            ),
          ),
          if (_isExpanded)
            Container(
              width: MediaQuery.of(context).size.width * 0.95,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          const Divider(color: Color(0xFFCACACA), thickness: 1.0),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCaseFiles,
              child: _caseFiles.isEmpty
                  ? const Center(child: Text('이 사건의 녹음이 없습니다.'))
                  : ListView.separated(
                      itemCount: _caseFiles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final f = _caseFiles[i];
                        return ListTile(
                          leading: Icon(
                            _playing == f['path']
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            color: _playing == f['path']
                                ? Colors.red
                                : const Color(0xFF577BE5),
                          ),
                          title: Text(f['name'],
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('용량: ${_fmtSize(f["bytes"])}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  // 이동
                                  GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.push<
                                          Map<String, dynamic>>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CaseFileSelectPage(
                                            sourceFile: File(f['path']),
                                            excludeTitles: [title, '이름 없는 파일'],
                                          ),
                                        ),
                                      );

                                      // ✅ 이동 완료 여부 확인
                                      if (result != null &&
                                          result['moved'] == true) {
                                        final destTitle =
                                            result['title'] as String;
                                        final destPath =
                                            result['toPath'] as String;
                                        final bytes = (f['bytes'] as int?) ?? 0;

                                        // ✅ 현재 화면 리스트 갱신
                                        setState(() {
                                          _caseFiles.removeAt(i);
                                          if (_playing == f['path'])
                                            _playing = null;
                                        });

                                        // ✅ data.json 업데이트
                                        final list = await _readDataJson();

                                        // source 감소
                                        final sIdx = list.indexWhere(
                                            (e) => (e['title'] ?? '') == title);
                                        if (sIdx >= 0) {
                                          final item =
                                              Map<String, dynamic>.from(
                                                  list[sIdx]);
                                          final oldCount =
                                              (item['count'] as num? ?? 0)
                                                  .toInt();
                                          final oldBytes = _parseSizeToBytes(
                                              item['size'] as String? ?? '0B');
                                          final newBytes = (oldBytes - bytes)
                                              .clamp(0, 1 << 62);
                                          item['count'] =
                                              (oldCount > 0) ? oldCount - 1 : 0;
                                          item['size'] = _formatBytes(newBytes);
                                          list[sIdx] = item;
                                        }

                                        // dest 증가
                                        final dIdx = list.indexWhere((e) =>
                                            (e['title'] ?? '') == destTitle);
                                        if (dIdx >= 0) {
                                          final item =
                                              Map<String, dynamic>.from(
                                                  list[dIdx]);
                                          final oldCount =
                                              (item['count'] as num? ?? 0)
                                                  .toInt();
                                          final oldBytes = _parseSizeToBytes(
                                              item['size'] as String? ?? '0B');
                                          final newBytes = oldBytes + bytes;
                                          item['count'] = oldCount + 1;
                                          item['size'] = _formatBytes(newBytes);
                                          item['recent'] =
                                              DateFormat('yyyy-MM-dd')
                                                  .format(DateTime.now());
                                          list[dIdx] = item;
                                        }
                                        await _writeDataJson(list);

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '‘$destTitle’로 이동 완료: ${p.basename(destPath)}'),
                                          ),
                                        );

                                        // ✅ 혹시 파일시스템 반영 느릴 경우 보완용
                                        await Future.delayed(
                                            const Duration(milliseconds: 300));
                                        await _loadCaseFiles();
                                      }
                                    },
                                    child: Image.asset(
                                      'assets/images/transfer.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  // 수정 (필요 없으면 삭제하거나 GPT 아이콘만 넣기)
                                  GestureDetector(
                                    onTap: () => _summarizeWithGPT(f),
                                    child: Image.asset(
                                        'assets/images/modify.png',
                                        width: 24,
                                        height: 24),
                                  ),
                                  const SizedBox(width: 14),

                                  // 삭제
                                  GestureDetector(
                                    onTap: () async {
                                      try {
                                        final bytes = (f['bytes'] as int?) ??
                                            await File(f['path']).length();
                                        await File(f['path']).delete();
                                        setState(() => _caseFiles.removeAt(i));
                                        if (_playing == f['path'])
                                          _playing = null;

                                        final list = await _readDataJson();
                                        final idx = list.indexWhere(
                                            (e) => (e['title'] ?? '') == title);
                                        if (idx >= 0) {
                                          final item =
                                              Map<String, dynamic>.from(
                                                  list[idx]);
                                          final oldCount =
                                              (item['count'] as num? ?? 0)
                                                  .toInt();
                                          final oldBytes = _parseSizeToBytes(
                                              item['size'] as String? ?? '0B');
                                          final newBytes = (oldBytes - bytes)
                                              .clamp(0, 1 << 62);
                                          item['count'] =
                                              (oldCount > 0) ? oldCount - 1 : 0;
                                          item['size'] = _formatBytes(newBytes);
                                          list[idx] = item;
                                          await _writeDataJson(list);
                                        }

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('삭제 완료')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('삭제 실패: $e')),
                                        );
                                      }
                                    },
                                    child: Image.asset(
                                        'assets/images/delete.png',
                                        width: 24,
                                        height: 24),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (_playing == f['path']) {
                              await _player.stop();
                              setState(() => _playing = null);
                            } else {
                              await _player.play(DeviceFileSource(f['path']));
                              setState(() => _playing = f['path']);
                            }
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _summarizeWithGPT(Map<String, dynamic> file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 240, 244, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '요약 중...',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final transcript = await transcribeWithWhisper(File(file['path']));
      final summary = await summarizeWithGPT(transcript);

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Color.fromARGB(255, 240, 244, 255),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            '요약 결과',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color.fromARGB(218, 255, 240, 240),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            '오류 발생',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}
