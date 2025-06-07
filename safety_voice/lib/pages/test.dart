import 'package:flutter/material.dart';

class CalendarHome extends StatefulWidget {
  const CalendarHome({super.key});

  @override
  State<CalendarHome> createState() => _CalendarHomeState();
}

class _CalendarHomeState extends State<CalendarHome> {
  bool isCalendarMode = true;

  final Color calendarBgColor = const Color(0xFFEFF3FF);
  final Color listBgColor = const Color(0xFFE3E7F6);

  final List<String> calendarDays = List.generate(31, (index) => (index + 1).toString());
  final int firstDayOfWeek = 1;
  final DateTime now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isCalendarMode ? calendarBgColor : listBgColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isCalendarMode ? '달력' : '파일 목록',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
      body: isCalendarMode ? _buildCalendarPopup() : const Center(child: Text("파일 목록 뷰")),
      floatingActionButton: isCalendarMode
          ? null
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: Color(0xFF577BE5),
              child: const Icon(Icons.add),
            ),


      bottomNavigationBar: SizedBox(
        height: 80, // 하단바 높이 증가
        child: Material(
          elevation: 20, // 그림자 더 짙게
          color: const Color.fromARGB(157, 0, 0, 0), // Material 배경 투명하게 (테두리 잘 보이게)
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

  Widget _buildCalendarPopup() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  DropdownButton<int>(
                    value: now.year,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF577BE5)),
                    underline: const SizedBox(),
                    items: List.generate(10, (index) {
                      int year = 2020 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year년', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF577BE5))),
                      );
                    }),
                    onChanged: (value) {},
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: now.month,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF577BE5)),
                    underline: const SizedBox(),
                    items: List.generate(12, (index) {
                      int month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text('$month월', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF577BE5))),
                      );
                    }),
                    onChanged: (value) {},
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: now.day,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF577BE5)),
                    underline: const SizedBox(),
                    items: List.generate(31, (index) {
                      int day = index + 1;
                      return DropdownMenuItem(
                        value: day,
                        child: Text('$day일', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF577BE5))),
                      );
                    }),
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/monday.png',
              fit: BoxFit.cover,
            ),
            Container(
              width: double.infinity,
              height: 1.0,
              color: const Color(0xFFCACACA),
            ),
            for (int i = 0; i < 5; i++) ...[
              SizedBox(
                height: 99.0,
                child: Row(
                  children: List.generate(7, (j) {
                    int dateIndex = i * 7 + j;
                    bool isToday = dateIndex >= firstDayOfWeek - 1 &&
                        dateIndex < calendarDays.length &&
                        calendarDays[dateIndex] == now.day.toString();

                    return Expanded(
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
                              color: isToday ? Color(0xFF577BE5) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              dateIndex < calendarDays.length
                                  ? calendarDays[dateIndex]
                                  : '',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: isToday ? Colors.white : Colors.black,
                                fontWeight:
                                    isToday ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (i != 4)
                Container(
                  width: double.infinity,
                  height: 1.0,
                  color: const Color(0xFFCACACA),
                ),
            ],
          ],
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
          color: selected ? Color(0xFF577BE5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}