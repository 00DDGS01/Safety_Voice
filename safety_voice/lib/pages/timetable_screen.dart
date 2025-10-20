import 'package:flutter/material.dart';

class TimeTableDemo extends StatefulWidget {
  const TimeTableDemo({super.key});

  @override
  State<TimeTableDemo> createState() => _TimeTableDemoState();
}

class _TimeTableDemoState extends State<TimeTableDemo> {
  // 선택된 셀 관리
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

  // 시간: 0~23시
  final List<int> times = List.generate(24, (index) => index);

  void toggleCell(int timeIdx, int dayIdx) {
    if (!mounted) return;
    setState(() {
      final cellId = '$timeIdx-$dayIdx';
      if (selected.contains(cellId)) {
        selected.remove(cellId);
      } else {
        selected.add(cellId);
      }
    });
  }

  // 선택된 셀들을 SafeTimeRequestDto에 맞는 구조로 변환
  List<Map<String, dynamic>> getSelectedSafeTimes() {
    final Map<String, List<int>> dayToHours = {};

    for (var cellId in selected) {
      final parts = cellId.split('-');
      final hourIdx = int.parse(parts[0]);
      final dayIdx = int.parse(parts[1]);
      final day = days[dayIdx];
      dayToHours.putIfAbsent(day, () => []).add(times[hourIdx]);
    }

    // 각 요일별로 연속된 시간 구간을 startTime ~ endTime 으로 묶기
    final List<Map<String, dynamic>> result = [];

    dayToHours.forEach((day, hours) {
      hours.sort();
      int? start;
      int? prev;

      for (int h in hours) {
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

  String _formatHour(int hour) {
    final formattedHour = hour.toString().padLeft(2, '0');
    return "$formattedHour:00";
  }

  void showTimeTableModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: const Text(
                    '타임 테이블 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),

                // 시간대 선택 영역
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
                              child: Text(
                                '${times[timeIdx]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          ...List.generate(days.length, (dayIdx) {
                            final cellId = '$timeIdx-$dayIdx';
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => toggleCell(timeIdx, dayIdx),
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: selected.contains(cellId)
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
                      final safeTimes = getSelectedSafeTimes();
                      print("✅ SafeTimeRequestDto 리스트: $safeTimes");
                      Navigator.pop(context, safeTimes);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF577BE5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('저장', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            );
          },
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
