import 'package:flutter/material.dart';

class TimeTableDemo extends StatefulWidget {
  const TimeTableDemo({super.key});

  @override
  State<TimeTableDemo> createState() => _TimeTableDemoState();
}

class _TimeTableDemoState extends State<TimeTableDemo> {
  final Set<String> selected = {};
  final List<String> days = ['일', '월', '화', '수', '목', '금', '토'];
  final Map<String, String> dayMap = {
    '일': 'SUN',
    '월': 'MON',
    '화': 'TUE',
    '수': 'WED',
    '목': 'THU',
    '금': 'FRI',
    '토': 'SAT',
  };

  final List<int> times = List.generate(24, (index) => index);

  String _formatHour(int hour) => hour.toString().padLeft(2, '0') + ':00';

  // ✅ SafeTimes 생성
  List<Map<String, dynamic>> getSelectedSafeTimes() {
    final Map<String, List<int>> dayToHours = {};
    for (var cellId in selected) {
      final parts = cellId.split('-');
      final hourIdx = int.parse(parts[0]);
      final dayIdx = int.parse(parts[1]);
      final day = days[dayIdx];
      dayToHours.putIfAbsent(day, () => []).add(times[hourIdx]);
    }

    final List<Map<String, dynamic>> result = [];
    dayToHours.forEach((day, hours) {
      hours.sort();
      int? start;
      int? prev;
      for (var h in hours) {
        if (start == null) {
          start = h;
          prev = h;
        } else if (h == prev! + 1) {
          prev = h;
        } else {
          result.add({
            "daysActive": dayMap[day],
            "startTime": _formatHour(start!),
            "endTime": _formatHour(prev! + 1),
          });
          start = h;
          prev = h;
        }
      }
      if (start != null && prev != null) {
        result.add({
          "daysActive": dayMap[day],
          "startTime": _formatHour(start),
          "endTime": _formatHour(prev! + 1),
        });
      }
    });
    return result;
  }

  // ✅ 모달 열기
  void showTimeTableModal(BuildContext context,
      {List<Map<String, dynamic>>? safeTimes}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _TimeTableSheet(
          initialSafeTimes: safeTimes, // 서버 값 전달
          parentSelected: selected, // 부모 선택 유지
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text(
          '타임테이블 테스트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => showTimeTableModal(context),
          child: const Text('타임테이블 열기'),
        ),
      ),
    );
  }
}

class _TimeTableSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? initialSafeTimes;
  final Set<String> parentSelected;

  const _TimeTableSheet({
    super.key,
    this.initialSafeTimes,
    required this.parentSelected,
  });

  @override
  State<_TimeTableSheet> createState() => _TimeTableSheetState();
}

class _TimeTableSheetState extends State<_TimeTableSheet> {
  late Set<String> selected;
  final List<String> days = ['일', '월', '화', '수', '목', '금', '토'];
  final List<int> times = List.generate(24, (index) => index);

  @override
  void initState() {
    super.initState();
    selected = {...widget.parentSelected};

    // ✅ 서버 safeTimes 있으면 자동 반영
    if (widget.initialSafeTimes != null &&
        widget.initialSafeTimes!.isNotEmpty) {
      for (var item in widget.initialSafeTimes!) {
        final dayIdx = _dayToIndex(item["daysActive"]);
        final start = item["startTime"]["hour"];
        final end = item["endTime"]["hour"];
        for (int hour = start; hour < end; hour++) {
          selected.add('$hour-$dayIdx');
        }
      }
      print('🟢 서버 safeTimes 반영 완료 (${selected.length}개 셀)');
    } else {
      print('ℹ️ 서버 safeTimes 없음 — 직접 선택 모드');
    }
  }

  int _dayToIndex(String day) {
    switch (day) {
      case 'SUN':
        return 0;
      case 'MON':
        return 1;
      case 'TUE':
        return 2;
      case 'WED':
        return 3;
      case 'THU':
        return 4;
      case 'FRI':
        return 5;
      case 'SAT':
        return 6;
      default:
        return 0;
    }
  }

  void toggleCell(int timeIdx, int dayIdx) {
    setState(() {
      final cellId = '$timeIdx-$dayIdx';
      if (selected.contains(cellId)) {
        selected.remove(cellId);
      } else {
        selected.add(cellId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              height: 50,
              alignment: Alignment.center,
              child: const Text(
                '타임 테이블 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Divider(height: 1, color: Colors.grey[300]),

            // 요일 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey[50],
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  ...days.map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )),
                ],
              ),
            ),

            // 시간대 선택
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: times.length,
                itemBuilder: (context, timeIdx) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: Text('${times[timeIdx]}'),
                        ),
                      ),
                      ...List.generate(days.length, (dayIdx) {
                        final cellId = '$timeIdx-$dayIdx';
                        final isSelected = selected.contains(cellId);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => toggleCell(timeIdx, dayIdx),
                            child: Container(
                              margin: const EdgeInsets.all(1),
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF577BE5)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            // 저장 버튼
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton(
                onPressed: () {
                  print("✅ 저장 클릭됨: ${selected.length}개 선택됨");
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF577BE5),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('저장', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }
}
