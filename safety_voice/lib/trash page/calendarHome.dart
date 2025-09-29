import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarHome extends StatelessWidget {
  const CalendarHome({super.key});

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('y년 M월 d일').format(DateTime.now());
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day; // 현재 월의 총 날짜 수
    int firstDayOfWeek = (DateTime(now.year, now.month, 1).weekday % 7) + 1;

    // 날짜 데이터를 생성 (빈칸 포함)
    List<String> calendarDays = [
      ...List.filled(firstDayOfWeek - 1, ''), // 첫 번째 주의 빈칸
      ...List.generate(
          daysInMonth, (index) => (index + 1).toString()), // 1일부터 말일까지 추가
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // AppBar 높이를 80으로 설정
        child: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            currentDate,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.05,
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const CalendarHome(),
                    transitionDuration: Duration.zero, // 애니메이션 시간을 0으로 설정
                    reverseTransitionDuration: Duration.zero, // 뒤로 가기 애니메이션도 제거
                  ),
                );
              },
              icon: Image.asset(
                'assets/images/calendar.png',
                height: 30,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/listhome'),
              icon: Image.asset(
                'assets/images/list_gray.png',
                height: 30,
              ),
            ),
            Container(width: 10),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Image.asset(
              'assets/images/monday.png',
              fit: BoxFit.cover,
            ),
            Container(
              width: double.infinity,
              height: 1.0,
              color: const Color(0xFFCACACA),
            ),
            // 5줄의 날짜 행을 생성
            for (int i = 0; i < 5; i++) ...[
              SizedBox(
                height: 99.0,
                child: Row(
                  children: List.generate(7, (j) {
                    int dateIndex = i * 7 + j; // 각 날짜의 인덱스 계산
                    bool isToday = dateIndex >= firstDayOfWeek - 1 &&
                        dateIndex < calendarDays.length &&
                        calendarDays[dateIndex] ==
                            now.day.toString(); // 오늘 날짜인지 확인

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 6.0),
                        child: Align(
                          alignment: Alignment.topLeft, // 텍스트를 왼쪽 위로 정렬
                          child: Container(
                            margin: const EdgeInsets.only(top: 1.0),
                            width: 23.0, // 정사각형 박스 크기
                            height: 23.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Colors.blue // 오늘 날짜는 파란색 배경
                                  : Colors.transparent, // 다른 날짜는 투명
                              borderRadius:
                                  BorderRadius.circular(4.0), // 네모박스의 둥근 모서리
                            ),
                            child: Text(
                              dateIndex < calendarDays.length
                                  ? calendarDays[dateIndex]
                                  : '', // 날짜가 범위 외면 빈칸
                              style: TextStyle(
                                fontSize: 14.0,
                                color: isToday
                                    ? Colors.white
                                    : Colors
                                        .black, // 오늘 날짜는 하얀 글씨, 다른 날짜는 검정 글씨
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight
                                        .normal, // 오늘 날짜는 bold, 다른 날짜는 normal
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Container(
                width: double.infinity,
                height: 1.0,
                color: const Color(0xFFCACACA),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 80, // 하단바 높이 증가
        child: Material(
          elevation: 20, // 그림자 더 짙게
          color: const Color.fromARGB(
              157, 0, 0, 0), // Material 배경 투명하게 (테두리 잘 보이게)
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF), // 하단바 배경 흰색
              border: Border(
                top: BorderSide(
                  color: const Color.fromARGB(255, 177, 177, 177), // 테두리 색 지정
                  width: 2.0,
                ),
              ),
            ),
            child: BottomAppBar(
              color: Colors.transparent, // 배경 투명 (상위 Container에서 처리)
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/calendarhome'),
                    child: Image.asset(
                      'assets/home/recordingList_.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/safezone'),
                    child: Image.asset(
                      'assets/home/wordRecognition.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/setup'),
                    child: Image.asset(
                      'assets/home/safeZone.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
