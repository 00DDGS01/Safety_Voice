import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isCalendarMode = true;

  final Color calendarBgColor = const Color(0xFFEFF3FF);
  final Color listBgColor = const Color(0xFFE3E7F6);

  final List<String> calendarDays = List.generate(31, (index) => (index + 1).toString());
  final int firstDayOfWeek = 1;
  final DateTime now = DateTime.now();

  List<dynamic> fileData = [];

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    final String response = await rootBundle.loadString('assets/data/data.json');
    final data = json.decode(response);
    setState(() {
      fileData = data;
    });
  }

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
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/home'),
                    child: Image.asset('assets/home/recordingList_.png', fit: BoxFit.contain),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/safezone'),
                    child: Image.asset('assets/home/wordRecognition.png', fit: BoxFit.contain),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/setup'),
                    child: Image.asset('assets/home/safeZone.png', fit: BoxFit.contain),
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
                    onTap: () => Navigator.pushNamed(context, '/nonamed'),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Text(
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
                    onTap: () => Navigator.pushNamed(context, '/casefile'),
                    child: _buildFileBox(
                      title: fileData[i - 1]['title'],
                      recent: fileData[i - 1]['recent'],
                      count: fileData[i - 1]['count'],
                      size: fileData[i - 1]['size'],
                      badgeColor: Color(int.parse(fileData[i - 1]['color'].replaceFirst('#', '0xFF'))),
                      textColor: Color(int.parse(fileData[i - 1]['textColor'].replaceFirst('#', '0xFF'))),
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
              onTap: () => Navigator.pushNamed(context, '/stoprecord'),
              child: Container(
                decoration: BoxDecoration(
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 10),
              Text("최근 추가일 : $recent", style: const TextStyle(color: Colors.black45,fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("파일 개수 : ${count}개", style: const TextStyle(color: Color(0xFF577BE5),fontSize: 12)),
              const SizedBox(height: 8),
              Text("전체 용량 : $size", style: const TextStyle(color: Color(0xFF577BE5),fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPopup() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
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
                              dateIndex < calendarDays.length ? calendarDays[dateIndex] : '',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: isToday ? Colors.white : Colors.black,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
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
