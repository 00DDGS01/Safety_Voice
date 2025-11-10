import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import 'package:safety_voice/pages/word_setting.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'package:safety_voice/pages/nonamed.dart';
import 'package:safety_voice/pages/caseFile.dart';
import 'package:safety_voice/pages/stopRecord.dart';
import 'package:safety_voice/pages/hint.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ===== 오디오 확장자 판정 =====
bool _isAudio(String path) {
  final ext = p.extension(path).toLowerCase();
  return ['.mp4', '.m4a', '.aac', '.wav', '.mp3', '.ogg'].contains(ext);
}

// ===== 바이트 → 문자열 포맷 =====
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

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isCalendarMode = true;

  // 연/월 드롭다운 상태 (일은 제거)
  late int _year;
  late int _month; // 1~12
  final DateTime _today = DateTime.now();

  List<dynamic> fileData = [];

  // 날짜별 녹음 라벨 데이터 (assets/data/records.json)
  Map<String, List<RecordBadge>> _records = {};

  final String _localFileName = 'data.json';

  // 사건 제목으로 폴더 경로
  Future<Directory> _caseDir(String title) async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, title));
  }

  // 폴더 스캔 (오디오 파일 개수/총용량/최근수정일 yyyy-MM-dd)
  Future<({int count, int bytes, String? recentYMD})> _scanCaseFolder(
      String title) async {
    final dir = await _caseDir(title);
    if (!await dir.exists()) return (count: 0, bytes: 0, recentYMD: null);

    int count = 0;
    int totalBytes = 0;
    DateTime? latest;

    await for (final ent in dir.list(followLinks: false)) {
      if (ent is File && _isAudio(ent.path)) {
        count++;
        totalBytes += await ent.length();
        final m = (await ent.stat()).modified;
        if (latest == null || m.isAfter(latest!)) latest = m;
      }
    }

    final recentYMD =
        latest == null ? null : DateFormat('yyyy-MM-dd').format(latest!);
    return (count: count, bytes: totalBytes, recentYMD: recentYMD);
  }

  // 홈 목록 전체 동기화 (실제 폴더 기준으로 fileData 덮어쓰기)
  Future<void> _reconcileAllCases() async {
    try {
      // fileData의 각 아이템: {"title","count","size","recent",...}
      final list = List<Map<String, dynamic>>.from(
          fileData.map((e) => Map<String, dynamic>.from(e)));
      bool changed = false;

      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        final title = (item['title'] ?? '').toString();
        if (title.isEmpty) continue;

        final scan = await _scanCaseFolder(title);
        final newCount = scan.count;
        final newSize = _formatBytes(scan.bytes);
        final newRecent = scan.recentYMD ?? (item['recent'] ?? '');

        if (item['count'] != newCount ||
            item['size'] != newSize ||
            item['recent'] != newRecent) {
          item['count'] = newCount;
          item['size'] = newSize;
          item['recent'] = newRecent;
          list[i] = item;
          changed = true;
        }
      }

      if (changed) {
        setState(() => fileData = list);
        await _saveFileData(); // 로컬 data.json 업데이트
      }
    } catch (e) {
      debugPrint('reconcileAllCases error: $e');
    }
  }

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localFileName');
  }

  Future<void> _saveFileData() async {
    final f = await _getLocalFile();
    await f.writeAsString(jsonEncode(fileData));
  }

  @override
  void initState() {
    super.initState();
    _year = _today.year;
    _month = _today.month;
    _loadJsonData().then((_) {
      _reconcileAllCases();
    });
    _loadRecordBadges();
  }

  Future<void> _loadJsonData() async {
    final String response =
        await rootBundle.loadString('assets/data/data.json');
    final data = json.decode(response);
    setState(() => fileData = data);
  }

  Future<void> _loadRecordBadges() async {
    try {
      final raw = await rootBundle.loadString('assets/data/records.json');
      final Map<String, dynamic> m = json.decode(raw);
      final map = <String, List<RecordBadge>>{};
      m.forEach((k, v) {
        final list = (v as List).map((e) => RecordBadge.fromJson(e)).toList();
        map[k] = list;
      });
      setState(() => _records = map);
    } catch (e) {
      debugPrint('records.json load error: $e');
    }
  }

  void _goToHint(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HintScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFEFF3FF);

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => _goToHint(context),
          behavior: HitTestBehavior.opaque,
          child: Transform.scale(
            scale: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset('assets/hint/hint.png'),
            ),
          ),
        ),
        title: Text(
          isCalendarMode ? '달력' : '파일 목록',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          _topModeButton(
            icon: Icons.calendar_today,
            selected: isCalendarMode,
            onTap: () => setState(() => isCalendarMode = true),
          ),
          const SizedBox(width: 8),
          _topModeButton(
            icon: Icons.menu,
            selected: !isCalendarMode,
            onTap: () => setState(() => isCalendarMode = false),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isCalendarMode ? _buildCalendarPopup() : _buildListMode(),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Material(
          elevation: 20,
          color: const Color.fromARGB(157, 0, 0, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border(
                top: BorderSide(
                  color: const Color.fromARGB(255, 177, 177, 177),
                  width: 2.0,
                ),
              ),
            ),
            child: BottomAppBar(
              color: Colors.transparent,
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Image.asset('assets/home/recordingList_.png',
                        fit: BoxFit.contain),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const SettingScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Image.asset('assets/home/wordRecognition.png',
                        fit: BoxFit.contain),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const SetupScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Image.asset('assets/home/safeZone.png',
                        fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListMode() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          children: [
            for (int i = 0; i < fileData.length + 1; i++)
              i == 0
                  ? GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Nonamed()),
                        );

                        await _reconcileAllCases(); // 또는 await _loadJsonData();
                        setState(() {});
                      },
                      child: Container(
                        height: 110,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  child: const Text(
                                    "이름 없는 파일",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => CaseFile(
                              data: fileData[i - 1],
                              onUpdate: (updated) async {
                                setState(() {
                                  fileData[i - 1] = updated;
                                });
                                await _saveFileData();
                              },
                            ),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        ).then((_) => _reconcileAllCases()); // ← 밑줄 붙인 메서드로!
                      },
                      child: _buildFileBox(
                        title: fileData[i - 1]['title'],
                        recent: fileData[i - 1]['recent'],
                        count: fileData[i - 1]['count'],
                        size: fileData[i - 1]['size'],
                        badgeColor: Color(int.parse(fileData[i - 1]['color']
                            .replaceFirst('#', '0xFF'))),
                        textColor: Color(int.parse(fileData[i - 1]['textColor']
                            .replaceFirst('#', '0xFF'))),
                      ),
                    )
          ],
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: GestureDetector(
            onTap: () => _openAddCaseSheet(context),
            child: Image.asset(
              'assets/images/plus.png', // plus.png 이미지 사용
              width: 60,
              height: 60,
            ),
          ),
        ),
        Positioned(
          bottom: 16.0,
          left: 16.0,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const StopRecord(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            child: Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.red),
              padding: const EdgeInsets.all(16.0),
              child: const Icon(Icons.mic, color: Colors.white, size: 30.0),
            ),
          ),
        ),
      ],
    );
  }

  // ===== 유틸 =====
  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  // 선택된 색에 "검정 비율을 섞은" 더 진한 색 (텍스트용)
  Color _mixWithBlack(Color base, [double t = 0.6]) {
    // t=0.6이면 base:40%, black:60% 블렌딩
    final r = (base.red * (1 - t)).round();
    final g = (base.green * (1 - t)).round();
    final b = (base.blue * (1 - t)).round();
    return Color.fromARGB(255, r, g, b);
  }

  // 제목 중복 검사 (_cases는 너의 리스트)
  bool _isTitleDuplicate(String title) =>
      fileData.any((e) => (e['title'] as String).trim() == title.trim());

  // ===== 모달 오픈 =====
  Future<void> _openAddCaseSheet(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    // 예시 팔레트(원하면 더 추가)
    final preset = <Color>[
      const Color(0xFFFDEDED), // 빨강 라이트
      const Color(0xFFEBF8ED), // 초록 라이트
      const Color(0xFFE7F0FE), // 파랑 라이트
      const Color(0xFFFFF4E0), // 주황 라이트
      const Color(0xFFEFEFEF), // 회색 라이트
    ];

    Color selected = preset[2]; // 기본 파랑 라이트

    void _showSheetSnack(BuildContext ctx, String message) {
      // 현재 스낵바 있으면 닫기
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 100,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 12, bottom: bottom + 16),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              // 한 줄 UI를 만들기 위한 공용 위젯
              Widget rowField(String label, Widget trailing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: trailing),
                      ],
                    ),
                  );

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 12),
                    const Text("사건 파일 추가",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // 제목(한 줄)
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

                    // 설명(한 줄 → 탭 시 여러 줄도 가능하도록)
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

                    // 색상(한 줄, 팔레트 선택)
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
                            onPressed: () => Navigator.pop(ctx, false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              final description = descCtrl.text.trim();

                              if (title.isEmpty) {
                                _showSheetSnack(ctx, '제목을 입력하세요');
                                return;
                              }
                              if (_isTitleDuplicate(title)) {
                                _showSheetSnack(ctx, '이미 존재하는 파일 이름입니다');
                                return;
                              }

                              final textColor = _mixWithBlack(selected, 0.6);
                              final now = DateTime.now();
                              final newItem = {
                                "title": title,
                                "description": description,
                                "color": _colorToHex(selected),
                                "textColor": _colorToHex(textColor),
                                "recent": DateFormat('yyyy-MM-dd').format(now),
                                "count": 0,
                                "size": "0GB",
                              };

                              setState(() => fileData.insert(0, newItem));
                              await _saveFileData();

                              if (mounted) Navigator.pop(ctx, true);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사건 파일을 추가했습니다.')),
      );
    }
  }

  Widget _buildFileBox({
    required String title,
    required String recent,
    required int count,
    required String size,
    Color badgeColor = Colors.white,
    Color textColor = Colors.black,
  }) {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Text(title,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(height: 10),
              Text("최근 추가일 : $recent",
                  style: const TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("파일 개수 : ${count}개",
                  style:
                      const TextStyle(color: Color(0xFF577BE5), fontSize: 12)),
              const SizedBox(height: 8),
              Text("전체 용량 : $size",
                  style:
                      const TextStyle(color: Color(0xFF577BE5), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /// =================== 달력 뷰 ===================
  Widget _buildCalendarPopup() {
    // 선택된 연/월 기준으로 달력 데이터 계산
    final int daysInMonth = DateTime(_year, _month + 1, 0).day; // 말일
    final int firstWeekday =
        DateTime(_year, _month, 1).weekday; // Mon=1..Sun=7 (Dart 규칙)
    // 헤더가 "일~토" 이므로 '일요일 시작' 기준: 선행 빈칸 = weekday % 7 (Sun:7 -> 0칸)
    final int leadingBlanks = firstWeekday % 7;

    final List<String> calendarDays = [
      ...List.filled(leadingBlanks, ''),
      ...List.generate(daysInMonth, (i) => (i + 1).toString()),
    ];

    final int totalCells = leadingBlanks + daysInMonth;
    final int rowCount = (totalCells / 7).ceil();

    bool isValidCell(int idx) =>
        idx >= 0 && idx < calendarDays.length && calendarDays[idx].isNotEmpty;

    bool isTodayCell(int idx) {
      if (!isValidCell(idx)) return false;
      final int day = int.parse(calendarDays[idx]);
      return _year == _today.year &&
          _month == _today.month &&
          day == _today.day;
    }

    final DateTime todayDateOnly =
        DateTime(_today.year, _today.month, _today.day);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.785,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 상단 드롭다운: 연/월만 (일 제거)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 연도
                    DropdownButton<int>(
                      value: _year,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF577BE5)),
                      underline: const SizedBox(),
                      items: List.generate(11, (i) => (_today.year - 5) + i)
                          .map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y년',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF577BE5))),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _year = v);
                      },
                    ),
                    const SizedBox(width: 10),

                    // 월
                    DropdownButton<int>(
                      value: _month,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF577BE5)),
                      underline: const SizedBox(),
                      items: List.generate(12, (i) => i + 1).map((m) {
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text('$m월',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF577BE5))),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _month = v);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Image.asset('assets/images/monday.png', fit: BoxFit.cover),
              Container(
                  width: double.infinity,
                  height: 1.0,
                  color: const Color(0xFFCACACA)),

              // 주(행) 동적 생성: 5 또는 6
              for (int i = 0; i < rowCount; i++) ...[
                SizedBox(
                  height: 99.0,
                  child: Row(
                    children: List.generate(7, (j) {
                      final int dateIndex = i * 7 + j;
                      final bool valid = isValidCell(dateIndex);

                      // 셀의 날짜(Date)
                      DateTime? cellDate;
                      if (valid) {
                        final int d = int.parse(calendarDays[dateIndex]);
                        cellDate = DateTime(_year, _month, d);
                      }

                      final bool isToday = valid && isTodayCell(dateIndex);
                      final bool isFuture =
                          valid && cellDate!.isAfter(todayDateOnly);

                      // 해당 날짜의 라벨들
                      final List<RecordBadge> items;
                      if (valid) {
                        final k = _dayKey(
                            _year, _month, int.parse(calendarDays[dateIndex]));
                        items = _records[k] ?? const <RecordBadge>[];
                      } else {
                        items = const <RecordBadge>[];
                      }

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!valid) return;
                            if (isFuture) return; // ✅ 오늘 이후는 터치 불가
                            _showDayDialog(
                                context, cellDate!, items); // ✅ 같은 아이템 그대로 전달
                          },
                          child: Opacity(
                            opacity: isFuture ? 0.4 : 1.0, // ✅ 미래 날짜는 살짝 흐리게
                            child: Container(
                              margin: const EdgeInsets.only(left: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 날짜 네모
                                  Container(
                                    margin: const EdgeInsets.only(top: 1.0),
                                    width: 23.0,
                                    height: 23.0,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? const Color(0xFF577BE5)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      valid ? calendarDays[dateIndex] : '',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: isToday
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // 날짜별 미니 뱃지들
                                  for (final b in items.take(4)) _miniBadge(b),
                                  if (items.length > 4)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Text('…',
                                          style: TextStyle(
                                              color: Colors.black45,
                                              fontSize: 11)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (i != rowCount - 1)
                  Container(
                      width: double.infinity,
                      height: 1.0,
                      color: const Color(0xFFCACACA)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(RecordBadge b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: b.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        b.title, // "1310  4분"
        style: TextStyle(
            fontSize: 7, height: 1.2, color: b.fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _topModeButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF577BE5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: selected ? Colors.white : Colors.black),
      ),
    );
  }
}

/// =================== 다이얼로그 & 모델 ===================

void _showDayDialog(
    BuildContext context, DateTime date, List<RecordBadge> items) {
  showGeneralDialog(
    context: context,
    barrierLabel: 'day-detail',
    barrierDismissible: true, // 밖을 탭하면 닫힘
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final scale = Tween<double>(begin: 0.95, end: 1.0)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
      final opacity = Tween<double>(begin: 0, end: 1).animate(anim);
      return Opacity(
        opacity: opacity.value,
        child: Transform.scale(
          scale: scale.value,
          child: Center(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 360, maxHeight: 520),
                child: _DayDialogBody(date: date, items: items),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DayDialogBody extends StatelessWidget {
  const _DayDialogBody({required this.date, required this.items});
  final DateTime date;
  final List<RecordBadge> items;

  @override
  Widget build(BuildContext context) {
    final titleDate = DateFormat('M월 d일 (E)', 'ko_KR').format(date);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(titleDate,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 내용
        if (items.isEmpty)
          const Expanded(
            child: Center(
              child: Text('이 날의 녹음이 없습니다.',
                  style: TextStyle(color: Colors.black54)),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = items[i];
                final hh = r.time.substring(0, 2);
                final mm = r.time.substring(2, 4);
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: r.bg, borderRadius: BorderRadius.circular(10)),
                    child: Text('$hh:$mm',
                        style: TextStyle(
                            color: r.fg, fontWeight: FontWeight.w700)),
                  ),
                  title: Text('${r.minutes}분 녹음',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  // subtitle: const Text('파일 1개', style: TextStyle(color: Colors.black45)), // 필요 없으면 숨김
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 상세/재생 등 연결(원하면 여기에)
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class RecordBadge {
  final String time; // "HHmm"
  final int minutes; // 러닝타임(분)
  final Color bg;
  final Color fg;
  final String title; // 칩 텍스트 (예: "1310  4분")

  RecordBadge({
    required this.time,
    required this.minutes,
    required this.bg,
    required this.fg,
    required this.title,
  });

  factory RecordBadge.fromJson(Map<String, dynamic> j) {
    Color parseHex(String hex) {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    }

    return RecordBadge(
      time: j['time'] as String,
      minutes: (j['minutes'] as num).toInt(),
      bg: parseHex(j['color'] as String),
      fg: parseHex(j['textColor'] as String),
      title: (j['title'] as String?) ??
          '${j['time']}  ${(j['minutes'] as num).toInt()}분',
    );
  }
}

String _dayKey(int y, int m, int d) =>
    '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
