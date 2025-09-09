import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:safety_voice/pages/word_setting.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'package:safety_voice/pages/nonamed.dart';
import 'package:safety_voice/pages/caseFile.dart';
import 'package:safety_voice/pages/stopRecord.dart';

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

  @override
  void initState() {
    super.initState();
    _year = _today.year;
    _month = _today.month;
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    final String response =
        await rootBundle.loadString('assets/data/data.json');
    final data = json.decode(response);
    setState(() {
      fileData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFEFF3FF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
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
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const Nonamed(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
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
                            pageBuilder: (_, __, ___) => const CaseFile(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
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
            onTap: () {},
            child: Image.asset(
              'assets/images/plus.png',
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
    );
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
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
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

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.785,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
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
                          child: Text(
                            '$y년',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF577BE5),
                            ),
                          ),
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
                          child: Text(
                            '$m월',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF577BE5),
                            ),
                          ),
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
                      final bool isToday = isTodayCell(dateIndex);

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!valid) return;
                            final int day = int.parse(calendarDays[dateIndex]);
                            final DateTime selected =
                                DateTime(_year, _month, day);
                            _onDayTapped(context, selected); // ✅ 날짜 팝업
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 6.0),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
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
                                    color:
                                        isToday ? Colors.white : Colors.black,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
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

/// 날짜 탭 시 팝업
void _onDayTapped(BuildContext context, DateTime date) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RecordingListSheet(selectedDate: date),
  );
}

/// 간단한 바텀시트(데모) — 실제 API 연결 시 교체
class _RecordingListSheet extends StatelessWidget {
  final DateTime selectedDate;
  const _RecordingListSheet({required this.selectedDate});

  Future<List<_Recording>> _fetch(DateTime d) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      _Recording(
        title: '샘플 녹음',
        durationSec: 75,
        createdAt: DateTime(d.year, d.month, d.day, 14, 12),
      ),
    ];
  }

  String _mmss(int sec) =>
      '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(selectedDate);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: FutureBuilder<List<_Recording>>(
          future: _fetch(selectedDate),
          builder: (context, snap) {
            final items = snap.data ?? [];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator()));
            }
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('녹음 리스트',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(title, style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.library_music_outlined,
                              size: 40, color: Colors.black26),
                          SizedBox(height: 8),
                          Text('해당 날짜의 녹음이 없습니다.',
                              style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = items[i];
                        return ListTile(
                          leading:
                              const CircleAvatar(child: Icon(Icons.graphic_eq)),
                          title: Text(r.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${DateFormat('HH:mm').format(r.createdAt)} • ${_mmss(r.durationSec)}'),
                          trailing: IconButton(
                            tooltip: '재생',
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {},
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Recording {
  final String title;
  final int durationSec;
  final DateTime createdAt;
  _Recording(
      {required this.title,
      required this.durationSec,
      required this.createdAt});
}
