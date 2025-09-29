import 'package:flutter/material.dart';

class TimeTableGrid extends StatefulWidget {
  const TimeTableGrid({Key? key}) : super(key: key);

  @override
  _TimeTableGridState createState() => _TimeTableGridState();
}

class _TimeTableGridState extends State<TimeTableGrid> {
  // 선택된 시간들을 저장하는 Set
  final Set<String> selectedTimes = {};
  
  // 요일 리스트
  final List<String> days = ['일', '월', '화', '수', '목', '금', '토'];
  
  // 시간 리스트 (1-17교시)
  final List<int> times = List.generate(17, (index) => index + 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('타임 테이블'),
        actions: [
          TextButton(
            onPressed: () {
              // 저장 로직 구현
            },
            child: Text(
              '저장',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 요일 헤더
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                // 시간 열을 위한 빈 박스
                SizedBox(width: 40),
                // 요일 표시
                ...days.map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
              ],
            ),
          ),
          // 시간표 그리드
          Expanded(
            child: ListView.builder(
              itemCount: times.length,
              itemBuilder: (context, timeIndex) {
                return Row(
                  children: [
                    // 교시 표시
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          '${times[timeIndex]}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    // 각 요일별 시간 셀
                    ...List.generate(
                      7,
                      (dayIndex) => Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                final cellId = '$timeIndex-$dayIndex';
                                if (selectedTimes.contains(cellId)) {
                                  selectedTimes.remove(cellId);
                                } else {
                                  selectedTimes.add(cellId);
                                }
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: selectedTimes.contains('$timeIndex-$dayIndex')
                                    ? Colors.blue
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 사용 예시
void main() {
  runApp(MaterialApp(
    home: TimeTableGrid(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}