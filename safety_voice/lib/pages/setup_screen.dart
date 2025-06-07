//안전지대
import 'package:flutter/material.dart';
import 'package:safety_voice/pages/word_setting.dart';
import 'package:safety_voice/pages/home.dart';
import 'package:safety_voice/pages/map_screen.dart';


// 타임테이블 버튼 추가된 SetupScreen 코드
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool isSafetyEnabled = true; // 초기값 ON
  bool isAlarmEnabled = true; // 초기값 ON

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // AppBar 높이를 80으로 설정
        child: AppBar(
          automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
          title:  Text(
            '이대광님의 설정 현황',
              style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                  ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
          TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsEditScreen()),
                );
              },
              child: const Text(
                '수정',
                style: TextStyle(
                  color: Color(0xFF787878),
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),


      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 99, // 높이를 99로 설정
                    padding: const EdgeInsets.all(26),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 🔹 왼쪽 이미지 (왼쪽 정렬 + 마진)
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Image.asset(
                                'assets/safety.png',
                                width: 87,
                                height: 20,
                              ),
                            ),
                          ),
                        ),

                        // 🔸 오른쪽 스위치
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Switch(
                              value: isSafetyEnabled,
                              onChanged: (value) {
                                setState(() => isSafetyEnabled = value);
                              },
                              activeColor: Colors.white,
                              activeTrackColor: const Color(0xFF577BE5),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: const Color(0xFFE6E6E6),
                            ),
                          ),
                        ),
                      ],
                    ),

                  ),
                  Container(
                    // margin: const EdgeInsets.symmetric(vertical: 8.0), // 여백 추가
                    width: double.infinity,
                    height: 1.0, // 실선 두께
                    color: Color(0xFFCACACA), // 실선 색상
                  ),
                  // 현재 상태
                  Container(
                    height: 99, // 높이를 99로 설정
                    padding: const EdgeInsets.all(26),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 🔹 왼쪽 이미지 (왼쪽 정렬 + 마진)
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Image.asset(
                                'assets/word.png',
                                width: 87,
                                height: 20,
                              ),
                            ),
                          ),
                        ),

                        // 🔸 오른쪽 스위치
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Switch(
                              value: isAlarmEnabled,
                              onChanged: (value) {
                                setState(() => isAlarmEnabled = value);  // ✅ 알림 스위치 전용 상태값
                              },
                              activeColor: Colors.white,
                              activeTrackColor: const Color(0xFF577BE5),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: const Color(0xFFE6E6E6),
                            ),
                          ),
                        ),
                      ],
                    ),

                  ),
                  Container(
                    // margin: const EdgeInsets.symmetric(vertical: 8.0), // 여백 추가
                    width: double.infinity,
                    height: 1.0, // 실선 두께
                    color: Color(0xFFCACACA), // 실선 색상
                  ),
      
                  Container(
                    height: 99, // 높이를 99로 설정
                    padding: const EdgeInsets.all(26),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 🔹 왼쪽 이미지 (왼쪽 정렬 + 마진)
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Image.asset(
                                'assets/state.png',
                                height: 20,
                              ),
                            ),
                          ),
                        ),

                        // 🔸 오른쪽 텍스트 (안전지대 1번)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                '안전지대 1번',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  ),
                  Container(
                            // margin: const EdgeInsets.symmetric(vertical: 8.0), // 여백 추가
                            width: double.infinity,
                            height: 1.0, // 실선 두께
                            color: Color(0xFFCACACA), // 실선 색상
                          ),

                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 🔹 이미지 영역 (flex: 3)
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Image.asset(
                                'assets/safelocation.png',
                                height: 20,
                              ),
                            ),
                          ),
                        ),

                        // 🔸 텍스트 영역 (flex: 4)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text('1번', style: TextStyle(color: Colors.black, fontSize: 14)),
                                  SizedBox(width: 8),
                                  Text('학교', style: TextStyle(color: Colors.black, fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: const [
                                  Text('2번', style: TextStyle(color: Colors.black, fontSize: 14)),
                                  SizedBox(width: 8),
                                  Text('집', style: TextStyle(color: Colors.black, fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: const [
                                  Text('3번', style: TextStyle(color: Colors.black, fontSize: 14)),
                                  SizedBox(width: 8),
                                  Text('부모님댁', style: TextStyle(color: Colors.black, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  ),
                  Container(
                            // margin: const EdgeInsets.symmetric(vertical: 8.0), // 여백 추가
                            width: double.infinity,
                            height: 1.0, // 실선 두께
                            color: Color(0xFFCACACA), // 실선 색상
                          ),

       
           
         
    // 타임테이블 열기 버튼
    buildTimeTableButton(),
         Container(
              // margin: const EdgeInsets.symmetric(vertical: 8.0), // 여백 추가
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: Color(0xFFCACACA), // 실선 색상
            ),

Container(
   height: 99, // 높이를 99로 설정
  padding: const EdgeInsets.all(26),
  decoration: const BoxDecoration(
    border: Border(
      bottom: BorderSide(color: Colors.black12),
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.start, // 모든 요소를 왼쪽으로 정렬
    children: [
      // 이미지: 왼쪽에 배치
      Image.asset(
        'assets/alrim.png', // 안전지대 위치 이미지 경로
        height: 20, // 이미지 크기
      ),
      
      // 빈 공간: 이미지와 텍스트 사이의 공간을 유지하기 위해
      const SizedBox(width: 90),

      // 텍스트: 왼쪽 정렬
      Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 왼쪽 정렬
        children: [
          Row(
children: [
  Padding(
    padding: const EdgeInsets.only(top: 10), // 위쪽에 10만큼의 여백 추가
    child: Text(
      '배터리 효율을 놓치지 않았습니까?', 
      style: TextStyle(
        color: Colors.black,
        fontSize: 9.5, // 글자 크기 축소
      ),
    ),
  ),
],

          ),
          const SizedBox(height: 4),
        
        ],
      ),
    ],
  ),
),
    Container(
              // margin: const EdgeInsets.symmetric(vertical: 8.0), // 여백 추가
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: Color(0xFFCACACA), // 실선 색상
            ),


  ],
             ),
           ),
         ),
         




        Container(
          height: 76, // 세로 크기 76
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFFFE1E1), // 배경색 FFE1E1
          child: const Center(
            child: Text(
              '광고',
              style: TextStyle(
                color: Color(0xFF787878), // 글자 색상 787878
                fontSize: 20, // 글자 크기 25
              ),
            ),
          ),
        )

     

  ],
  
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
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const Home(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Image.asset('assets/home/recordingList.png', fit: BoxFit.contain),
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
                  child: Image.asset('assets/home/wordRecognition.png', fit: BoxFit.contain),
                ),
                TextButton(
                  onPressed: () {
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Image.asset('assets/home/safeZone_.png', fit: BoxFit.contain),
                ),
              ],

            ),
          ),
        ),
      ),
    ),
    );
  }

  // 타임테이블 열기 버튼 공통 위젯
Widget buildTimeTableButton() {
  return Container(
    padding: const EdgeInsets.all(26),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.black12)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image.asset(
          'assets/safetime.png',
          height: 20,
        ),
        const SizedBox(width: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('1번', style: TextStyle(color: Colors.black, fontSize: 14)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TimeTableModal(
                      safeZone: '안전지대 1번',
                      isEditing: false, // ✅ 추가
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '타임 테이블 열람',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('2번', style: TextStyle(color: Colors.black, fontSize: 14)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TimeTableModal(
                      safeZone: '안전지대 2번',
                      isEditing: false, // ✅ 추가
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '타임 테이블 열람',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('3번', style: TextStyle(color: Colors.black, fontSize: 14)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TimeTableModal(
                      safeZone: '안전지대 3번',
                      isEditing: false, // ✅ 추가
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '타임 테이블 열람',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  }


  // SwitchListTile 공통 위젯
  Widget buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  // 일반 정보 표시 공통 위젯
  Widget buildInfoRow(String title, String content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            content,
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  // 하단 메뉴 공통 위젯
  Widget buildBottomMenuItem(String top, String bottom) {
    return Column(
      children: [
        Text(top),
        Text(bottom),
      ],
    );
  }
}



class TimeTableModal extends StatefulWidget {
  final String safeZone; // 안전지대 번호를 저장할 변수
  final bool isEditing;

  const TimeTableModal({super.key, required this.safeZone, required this.isEditing,});

  @override
  State<TimeTableModal> createState() => _TimeTableModalState();
}

class _TimeTableModalState extends State<TimeTableModal> {
  final Set<String> selected = {};
  final List<String> days = ['일', '월', '화', '수', '목', '금', '토'];
  final List<int> times = List.generate(24, (index) => index + 1);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 좌우로 배치
              children: [
                // 🔹 왼쪽: 뒤로가기 + 타이틀
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '타임 테이블',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // 🔸 오른쪽: 저장 버튼
                if (widget.isEditing)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF577BE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '저장',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 🔽 안전지대 번호
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${widget.safeZone} ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
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
                            width: 52,
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
        ],
      ),
    );
  }
}

class SettingsEditScreen extends StatefulWidget {
  @override
  _SettingsEditScreenState createState() => _SettingsEditScreenState();
}

class _SettingsEditScreenState extends State<SettingsEditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
     appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // AppBar 높이를 80으로 설정
        child: AppBar(
        backgroundColor: Colors.white,
        
    
      title: Text(
        '설정값 수정',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: MediaQuery.of(context).size.width * 0.05,
        ),
        ),
   
      ),
     ),
     body: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 0.0),
 child: SingleChildScrollView(
   child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
Container(
  padding: const EdgeInsets.symmetric(horizontal: 15.0),
  width: double.infinity,
  height: 180,
  color: Colors.transparent,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSafeZoneTitle('안전지대 1번'),
      buildLocationRow('위치', '주소를 입력해 주세요'),
      buildTimeRow('시간', '안전지대 1번'),
    ],
  ),
),

       Container(
         width: double.infinity,
         height: 1,
         color: const Color(0xFFCACACA),
       ),
       
Container(
    padding: const EdgeInsets.symmetric(horizontal: 15.0),
  width: double.infinity,
  height: 180,
  color: Colors.transparent,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSafeZoneTitle('안전지대 2번'),
      buildLocationRow('위치', '주소를 입력해 주세요'),
      buildTimeRow('시간', '안전지대 2번'),
    ],
  ),
),

       Container(
         width: double.infinity,
         height: 1,
         color: const Color(0xFFCACACA),
       ),
       
    Container(
       padding: const EdgeInsets.symmetric(horizontal: 15.0),
  width: double.infinity,
  height: 180,
  color: Colors.transparent,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSafeZoneTitle('안전지대 2번'),
      buildLocationRow('위치', '주소를 입력해 주세요'),
      buildTimeRow('시간', '안전지대 3번'),
    ],
  ),
),

       Container(
         width: double.infinity,
         height: 1,
         color: const Color(0xFFCACACA),
       ),


Container(
  width: double.infinity,
  height: 99,
  color: Colors.transparent,
  padding: const EdgeInsets.symmetric(horizontal: 15.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      // 왼쪽에 이미지
      Padding(
        padding: const EdgeInsets.only(right: 0.0), // 이미지와 텍스트 사이 간격 없애기
        child: Image.asset(
          'assets/battery_icon.png', // 이미지 경로
          height: 20,
        ),
      ),
      // 오른쪽에 텍스트
      Padding(
        padding: const EdgeInsets.only(left: 26.0), // 텍스트와 이미지 사이 간격 없애기
        child: buildBatteryEfficiencyRow('배터리 효율을 높이시겠습니까?'),
      ),
    ],
  ),
),
     Container(
              // margin: const EdgeInsets.symmetric(vertical: 8.0), // 여백 추가
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: Color(0xFFCACACA), // 실선 색상
            ),
       const SizedBox(height: 50),
       
      Center(
  child: ElevatedButton(
    onPressed: () {
    Navigator.pop(context);},
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF577BE5), // 버튼 배경 색상
      minimumSize: const Size(350, 58), // 버튼 크기 (가로 350, 세로 58)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // 모서리 둥글게
      ),
    ),
    child: const Text(
      '설정값 수정하기',
      style: TextStyle(
        fontSize: 20,
        color: Colors.white, // 글자 색상 흰색
      ),
    ),
  ),
)
,
       
       const SizedBox(height: 16),
    Container(

  height: 76, // 세로 크기 76
  padding: const EdgeInsets.all(16),
  color: const Color(0xFFFFE1E1), // 배경색 FFE1E1
  child: const Center(
    child: Text(
      '광고',
      style: TextStyle(
        color: Color(0xFF787878), // 글자 색상 787878
        fontSize: 20, // 글자 크기 25
      ),
    ),
  ),
)

     ],
   ),
 ),
),
 
    );
  }

Widget buildSafeZoneTitle(String title) {
 String imagePath;
 switch(title) {
   case '안전지대 1번':
     imagePath = 'assets/safezone1.png';
     break;
   case '안전지대 2번':
     imagePath = 'assets/safezone2.png';
     break;
   case '안전지대 3번':
     imagePath = 'assets/safezone3.png';
     break;
   default:
     imagePath = 'assets/safezone.png';
 }
 
 return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
  //  padding: const EdgeInsets.only(top: 32.0), 
   child: Image.asset(
     imagePath,
     height: 20,
   ),
 );
}
Widget buildLocationRow(String label, String hint) {
  return Row(
    children: [
      SizedBox(
        width: 50,
        child: Text(label, style: const TextStyle(fontSize: 20)),
      ),
      const SizedBox(width: 16),
      Padding(
        padding: const EdgeInsets.only(right: 8.0), // 마진 값 조정
        child: Container(
          width: 220,
          height: 27,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF787878),
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MapScreen(), // 실제 위젯 이름으로 바꿔주세요
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },

  style: TextButton.styleFrom(
    backgroundColor: const Color(0xFFD9D9D9),
    minimumSize: const Size(67, 27),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    padding: EdgeInsets.zero,
  ),
  child: const Text(
    '주소 검색',
    style: TextStyle(
      color: Colors.black,
      fontSize: 15,
    ),
  ),
),
    ],
  );
}
Widget buildBatteryEfficiencyRow(String hint) {
  return Row(
    children: [
      const SizedBox(width: 0), // 레이블 없이 빈 공간을 없앰
      const SizedBox(width: 16),
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          width: 228,
          height: 27,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF787878),
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildTimeRow(String label, String safeZone) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 20)),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => TimeTableModal(
                safeZone: safeZone,     // 🔹 기존에 넘기던 안전지대
                isEditing: true,        // 🔹 "작성" 모드 표시
              ),
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFD9D9D9),
            minimumSize: const Size(110, 27),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            '타임 테이블 작성',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ),

      ],
    ),
  );
}


Widget buildTextRow(String label, String hint) {
  return Container(
    height: 50, // 높이 조정
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // 패딩 값 조정
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(4),
    ),
    child: TextField(
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
    ),
  );
}

}