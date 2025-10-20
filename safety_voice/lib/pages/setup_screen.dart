import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'package:safety_voice/pages/home.dart';
import 'package:safety_voice/pages/map_screen.dart';
import 'package:safety_voice/pages/word_setting.dart';
import 'package:safety_voice/services/api_client.dart';

import 'dart:async';
import 'dart:math';

// 타임테이블 버튼 추가된 SetupScreen 코드
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool isEditing = false;
  bool isSafetyEnabled = true; // 초기값 ON
  bool isAlarmEnabled = true; // 초기값 ON

  final TextEditingController notiWordController =
      TextEditingController(text: '배터리 효율을 높이시겠습니까?');

  final TextEditingController wordController =
      TextEditingController(text: '잠만');
  final TextEditingController recordSecondsController =
      TextEditingController(text: '2');
  final TextEditingController recordCountController =
      TextEditingController(text: '3');
  final TextEditingController emergencyCountController =
      TextEditingController(text: '5');
  final List<TextEditingController> phoneControllers = List.generate(
    3,
    (index) => TextEditingController(
      text: index == 0 ? '112' : '010-1234-5678',
    ),
  );

  List<Map<String, dynamic>>? safeTimesForZone1;

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFEFF3FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: const Color(0xFFEFF3FF),
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: isEditing
                  ? Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => isEditing = false);
                          },
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            '설정값 수정',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        const Center(
                          child: Text(
                            '사용자님의 설정 현황',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: TextButton(
                            onPressed: () {
                              setState(() => isEditing = true);
                            },
                            child: const Text(
                              '수정',
                              style: TextStyle(
                                color: Color(0xFF6B73FF),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        if (!isEditing) ...[
                          // 일반 보기 모드
                          _chooseSafeZoneSection(),
                          SizedBox(height: 25),
                          _chooseNotiSection(),
                          SizedBox(height: 25),
                          _buildNowStateSection(),
                          SizedBox(height: 25),
                          _buildLocationSection(),
                          SizedBox(height: 30),
                          _buildNotiWordSection(),
                        ] else ...[
                          // 편집 모드
                          _buildLocationOneSection('안전지대 1번'),
                          SizedBox(height: 12),
                          const Divider(
                              color: Color(0xFFCACACA), thickness: 1.0),
                          SizedBox(height: 12),
                          _buildLocationTwoSection('안전지대 2번'),
                          SizedBox(height: 12),
                          const Divider(
                              color: Color(0xFFCACACA), thickness: 1.0),
                          SizedBox(height: 12),
                          _buildLocationThreeSection('안전지대 3번'),
                          SizedBox(height: 12),
                          const Divider(
                              color: Color(0xFFCACACA), thickness: 1.0),
                          SizedBox(height: 12),
                          _buildEditNotiWordSection(),
                          SizedBox(height: 40),
                          // 설정값 수정하기 버튼
                          Container(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (safeTimesForZone1 == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('타임테이블을 먼저 설정하세요!')),
                                  );
                                  return;
                                }

                                final body = [
                                  {
                                    "safeZoneName": "학교",
                                    "location": "청주시 서원구 개신동 54",
                                    "radius": 200,
                                    "safeTimes": safeTimesForZone1,
                                  }
                                ];

                                print("📤 SafeZone POST Body: $body");

                                try {
                                  final response = await ApiClient.put(
                                      "/api/safe-zones", body);
                                  if (response.statusCode == 200 ||
                                      response.statusCode == 201) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('✅ 안전지대가 저장되었습니다!')),
                                    );
                                    setState(() =>
                                        isEditing = false); // 저장 성공 시 보기모드로 전환
                                  } else {
                                    print("❌ 서버 오류: ${response.statusCode}");
                                    print("응답: ${response.body}");
                                  }
                                } catch (e) {
                                  print("🚨 예외 발생: $e");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6B73FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '설정값 수정하기',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 학습 모달
        ],
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
                    child: Image.asset('assets/home/recordingList.png',
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
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Image.asset('assets/home/safeZone_.png',
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

  // 일반 보기 모드 위젯들
  Widget _chooseSafeZoneSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "안전 지대",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
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
    );
  }

  Widget _chooseNotiSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "알림 허용",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: Switch(
                value: isAlarmEnabled,
                onChanged: (value) {
                  setState(() => isAlarmEnabled = value);
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
    );
  }

  Widget _buildNowStateSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Text(
            '현재 상태',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Container(
            width: 190,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFE8EAFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "안전지대 1번",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B73FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1번 - 첫 번째 줄 (1번 + 112)
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 0),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Spacer(),
              Text(
                '1번',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "학교",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => TimeTableModal(
                    safeZone: '안전지대 1번',
                    isEditing: false,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Image.asset(
                    'assets/clock.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 2번 - 두 번째 줄
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 0),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Text(
                '안전지대 위치',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                '2번',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "집",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => TimeTableModal(
                    safeZone: '안전지대 2번',
                    isEditing: false,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Image.asset(
                    'assets/clock.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 3번 - 세 번째 줄 (3번 + 전화번호)
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Spacer(),
              Text(
                '3번',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "부모님댁",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
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
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Image.asset(
                    'assets/clock.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotiWordSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Text(
            '알림 문구',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Container(
            width: 190,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFE8EAFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                notiWordController.text,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B73FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// 편집 모드 위젯들
  Widget _buildLocationOneSection(String safeZone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 제목
          const Text(
            '안전지대 1번',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '위치',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: '청주시 서원구 개신동 54, 충북빌라',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          const MapScreen(), // 🔹 실제 지도 화면 위젯
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B73FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  textStyle: TextStyle(fontSize: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('주소 검색'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '시간',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final result =
                      await showModalBottomSheet<List<Map<String, dynamic>>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TimeTableModal(
                      safeZone: safeZone,
                      isEditing: true,
                    ),
                  );

                  if (result != null) {
                    print('✅ ${safeZone} SafeTimes: $result');
                    // 나중에 서버 전송 시 활용할 변수에 저장
                    setState(() {
                      safeTimesForZone1 = result;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/clock.png', width: 16, height: 16),
                      const SizedBox(width: 6),
                      const Text(
                        '타임테이블 작성',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B73FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTwoSection(String safeZone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 제목
          const Text(
            '안전지대 2번',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '위치',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: '청주시 서원구 개신동 1, 충북대학교',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          const MapScreen(), // 🔹 실제 지도 화면 위젯
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B73FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  textStyle: TextStyle(fontSize: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('주소 검색'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '시간',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TimeTableModal(
                      safeZone: safeZone, // 🔹 넘기는 안전지대 이름
                      isEditing: true, // 🔹 작성 모드
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/clock.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '타임테이블 작성',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B73FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationThreeSection(String safeZone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 제목
          const Text(
            '안전지대 3번',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '위치',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: '대전광역시 유성구 반석동로 123, 108동',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          const MapScreen(), // 🔹 실제 지도 화면 위젯
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B73FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  textStyle: TextStyle(fontSize: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('주소 검색'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '시간',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TimeTableModal(
                      safeZone: safeZone, // 🔹 넘기는 안전지대 이름
                      isEditing: true, // 🔹 작성 모드
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/clock.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '타임테이블 작성',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B73FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditNotiWordSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '알림 문구',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Container(
                width: 190,
                height: 40,
                child: TextField(
                  controller: notiWordController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '배터리 효율을 높이시겠습니까?',
                    hintStyle: TextStyle(
                        color: Color.fromARGB(139, 107, 114, 255)
                            .withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    notiWordController.dispose();

    wordController.dispose();
    recordSecondsController.dispose();
    recordCountController.dispose();
    emergencyCountController.dispose();
    for (var controller in phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class TimeTableModal extends StatefulWidget {
  final String safeZone; // 안전지대 번호를 저장할 변수
  final bool isEditing;

  const TimeTableModal({
    super.key,
    required this.safeZone,
    required this.isEditing,
  });

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

  String _formatHour(int hour) => hour.toString().padLeft(2, '0') + ':00';

  List<Map<String, dynamic>> _convertToSafeTimeFormat() {
    final Map<int, List<int>> selectedByDay = {};
    for (var cell in selected) {
      final parts = cell.split('-');
      final timeIdx = int.parse(parts[0]);
      final dayIdx = int.parse(parts[1]);
      selectedByDay.putIfAbsent(dayIdx, () => []).add(timeIdx);
    }

    final dayMap = {
      0: 'SUN',
      1: 'MON',
      2: 'TUE',
      3: 'WED',
      4: 'THU',
      5: 'FRI',
      6: 'SAT',
    };

    final result = <Map<String, dynamic>>[];
    selectedByDay.forEach((dayIdx, hours) {
      hours.sort();
      int? start;
      int? prev;
      for (var hour in hours) {
        if (start == null) {
          start = hour;
          prev = hour;
        } else if (hour == prev! + 1) {
          prev = hour;
        } else {
          result.add({
            'daysActive': dayMap[dayIdx],
            'startTime': _formatHour(start),
            'endTime': _formatHour(prev! + 1),
          });
          start = hour;
          prev = hour;
        }
      }
      if (start != null) {
        result.add({
          'daysActive': dayMap[dayIdx],
          'startTime': _formatHour(start),
          'endTime': _formatHour(prev! + 1),
        });
      }
    });
    return result;
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
                    onTap: () {
                      final safeTimes = _convertToSafeTimeFormat();
                      print('✅ SafeTimes 반환: $safeTimes');
                      Navigator.pop(context, safeTimes); // 모달 닫으면서 데이터 전달
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
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
