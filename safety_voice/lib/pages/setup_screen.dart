import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'package:safety_voice/pages/home.dart';
import 'package:safety_voice/pages/map_screen.dart';
import 'package:safety_voice/pages/word_setting.dart';
import 'package:safety_voice/services/api_client.dart';
import 'package:http/http.dart';

import 'dart:async';
import 'dart:math';
import 'package:safety_voice/pages/hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 타임테이블 버튼 추가된 SetupScreen 코드
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  @override
  void initState() {
    _loadSafeZoneData();
  }

  bool isEditing = false;
  bool isSafetyEnabled = true; // 초기값 ON
  bool isAlarmEnabled = true; // 초기값 ON

  // 🔹 알림 문구
  final TextEditingController notiWordController =
      TextEditingController(text: '배터리 효율을 높이시겠습니까?');

  // 🔹 트리거 관련
  final TextEditingController wordController =
      TextEditingController(text: '잠만');
  final TextEditingController recordSecondsController =
      TextEditingController(text: '2');
  final TextEditingController recordCountController =
      TextEditingController(text: '3');
  final TextEditingController emergencyCountController =
      TextEditingController(text: '5');

  // 🔹 비상 연락처
  final List<TextEditingController> phoneControllers = List.generate(
    3,
    (index) => TextEditingController(
      text: index == 0 ? '112' : '010-1234-5678',
    ),
  );

  // ✅ (1) 안전지대 이름 + 위치를 위한 컨트롤러 하나만 (예: 학교, 집 등)
  final TextEditingController zone1LocationController =
      TextEditingController(text: "학교");

  // ✅ (2) 안전지대 1번의 시간 데이터
  List<Map<String, dynamic>>? safeTimesForZone1;

  // ✅ (3) 실제 서버로 보낼 safeZones 리스트 (1개만 사용)
  List<Map<String, dynamic>> safeZones = [
    {
      "safeZoneName": "학교",
      "latitude": null,
      "longitude": null,
      "radius": null,
      "safeTimes": [],
    },
  ];

  final TextEditingController safeZone1NameController =
      TextEditingController(text: "학교");

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

  Future<void> _loadSafeZoneData() async {
    print("🧭 SetupScreen initState() 실행됨 — 안전지대 불러오기 시작");

    // 1️⃣ 서버에서 최신 데이터 받아 SharedPreferences에 저장
    await ApiClient.fetchSafeZones();

    // 2️⃣ SharedPreferences에서 꺼내서 UI에 반영
    final prefs = await SharedPreferences.getInstance();
    final safeZoneName = prefs.getString('safeZoneName') ?? '';
    final latitude = prefs.getDouble('safeZoneLatitude');
    final longitude = prefs.getDouble('safeZoneLongitude');
    final radius = prefs.getInt('safeZoneRadius');

    print("📥 SharedPreferences 값 로드됨: $safeZoneName / $latitude / $longitude");

    // 3️⃣ controller와 state 업데이트
    setState(() {
      zone1LocationController.text = safeZoneName;
      safeZones[0] = {
        "safeZoneName": safeZoneName,
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
        "safeTimes": [],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFEFF3FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90), // 높이 크게 쓰고 싶으면 유지
        child: AppBar(
          backgroundColor: const Color(0xFFEFF3FF),
          elevation: 0,
          automaticallyImplyLeading: false, // 우리가 직접 leading 제어
          centerTitle: true,

          // 툴바 높이/좌우 여유 조정
          toolbarHeight: 90, // ← PreferredSize와 맞춤
          titleSpacing: 0, // ← 좌측여백 기본 제거(디자인에 따라 조절)
          leadingWidth: 56, // ← 좌우 균형 고정폭 (actions와 맞춤)

          // 좌측: 편집이면 뒤로가기, 아니면 hint.png (동일 라인)
          leading: isEditing
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.black, size: 22),
                  onPressed: () => setState(() => isEditing = false),
                )
              : GestureDetector(
                  onTap: () => _goToHint(context),
                  behavior: HitTestBehavior.opaque,
                  child: Align(
                    // ✅ 수직 가운데 정렬
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset('assets/hint/hint.png'),
                      ),
                    ),
                  ),
                ),

          // 중앙 제목: 상태별 변경
          title: Text(
            isEditing ? '설정값 수정' : '사용자님의 설정 현황',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),

          // 우측: 편집 중이면 비워서 중앙 정렬 유지, 아니면 '수정' 버튼
          actions: [
            if (isEditing)
              const SizedBox(width: 56) // leadingWidth와 동일 → 항상 정확히 중앙
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () => setState(() => isEditing = true),
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
                          // _buildNowStateSection(),
                          // SizedBox(height: 25),
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
                                // ✅ 안전지대 이름(=위치명) 비어있는 경우
                                if (zone1LocationController.text
                                    .trim()
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('안전지대 이름(위치명)을 입력하세요!')),
                                  );
                                  return;
                                }

                                // ✅ 지도에서 선택하지 않은 경우
                                final currentZone = safeZones[0];
                                if (currentZone["latitude"] == null ||
                                    currentZone["longitude"] == null ||
                                    currentZone["radius"] == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('먼저 주소 검색을 통해 위치를 선택하세요!')),
                                  );
                                  return;
                                }

                                // ✅ 서버에 보낼 body 생성 (safeTimes 없어도 OK)
                                final body = [
                                  {
                                    "safeZoneName":
                                        zone1LocationController.text.trim(),
                                    "latitude": currentZone["latitude"],
                                    "longitude": currentZone["longitude"],
                                    "radius": currentZone["radius"],
                                    if (safeTimesForZone1 != null &&
                                        safeTimesForZone1!.isNotEmpty)
                                      "safeTimes": safeTimesForZone1,
                                  }
                                ];

                                print("📤 SafeZone PUT Body: $body");

                                // ✅ 로딩 인디케이터 표시
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator()),
                                );

                                /*try {
                                  final result = await ApiClient.put(
                                      "/api/safe-zones", body);

                                  Navigator.pop(context);

                                  if (result["success"] == true) {
                                    // ✅ PUT 성공 후 서버에서 최신값 다시 불러오기
                                    await ApiClient.fetchSafeZones();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('✅ 안전지대 위치가 저장되었습니다!')),
                                    );
                                    setState(() => isEditing = false);
                                  } else {
                                    print("❌ 서버 오류: ${result["error"]}");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('서버 오류가 발생했습니다.')),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.pop(context);
                                  print("🚨 네트워크 예외: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.'),
                                    ),
                                  );
                                }
                                */
                                try {
                                  final result = await ApiClient.put(
                                      "/api/safe-zones", body);

                                  Navigator.pop(context); // ✅ 로딩창 닫기

                                  if (result["success"] == true) {
                                    // SharedPreferences에 안전지대 정보 동기화
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString('safeZoneName',
                                        zone1LocationController.text.trim());
                                    await prefs.setDouble(
                                      'safeZoneLatitude',
                                      (currentZone["latitude"] ?? 0.0)
                                          .toDouble(),
                                    );
                                    await prefs.setDouble(
                                      'safeZoneLongitude',
                                      (currentZone["longitude"] ?? 0.0)
                                          .toDouble(),
                                    );
                                    await prefs.setInt(
                                      'safeZoneRadius',
                                      (currentZone["radius"] ?? 0).toInt(),
                                    );
                                    if (safeTimesForZone1 != null &&
                                        safeTimesForZone1!.isNotEmpty) {
                                      await prefs.setString('safeZoneTimes',
                                          safeTimesForZone1.toString());
                                    }

                                    print(
                                        "💾 SharedPreferences에 안전지대 정보 저장 완료");

                                    // ✅ 추가: UI 즉시 반영
                                    setState(() {
                                      safeZones[0] = currentZone;
                                      zone1LocationController.text =
                                          currentZone["safeZoneName"];
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('✅ 안전지대 위치가 저장되었습니다!')),
                                    );
                                    setState(() => isEditing = false);
                                  } else {
                                    final status = result["statusCode"];
                                    final error = result["error"];
                                    print("❌ 서버 오류 ($status): $error");

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('서버 오류가 발생했습니다. ($status)')),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.pop(context); // ✅ 로딩창 닫기
                                  print("🚨 네트워크 예외: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            '네트워크 오류가 발생했습니다. 다시 시도해주세요.')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B73FF),
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

//현재 상태
  // Widget _buildNowStateSection() {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  //     child: Row(
  //       children: [
  //         Text(
  //           '현재 상태',
  //           style: TextStyle(
  //             fontSize: 16,
  //             color: Colors.black,
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),
  //         Spacer(),
  //         Container(
  //           width: 190,
  //           padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
  //           decoration: BoxDecoration(
  //             color: Color(0xFFE8EAFF),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Center(
  //             child: Text(
  //               "안전지대 1번",
  //               style: TextStyle(
  //                 fontSize: 15,
  //                 color: Color(0xFF6B73FF),
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
                    zone1LocationController.text.isNotEmpty
                        ? zone1LocationController.text
                        : "안전지대 미설정",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  // 🟢 1️⃣ 서버 최신 데이터 먼저 불러오기
                  await ApiClient.fetchSafeZones();

                  // 🟢 2️⃣ SharedPreferences에서 safeTimes 읽기
                  final prefs = await SharedPreferences.getInstance();
                  final saved = prefs.getString('safeZoneTimes');
                  List<Map<String, dynamic>>? safeTimes;

                  if (saved != null) {
                    safeTimes = (jsonDecode(saved) as List)
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();
                    print("💾 불러온 safeTimes: $safeTimes");
                  } else {
                    print("ℹ️ 서버에 저장된 safeTimes 없음 — 새로 작성 모드");
                  }

                  // 🟢 3️⃣ safeTimes를 TimeTableModal로 전달
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TimeTableModal(
                      safeZone: '안전지대 1번',
                      isEditing: true,
                      safeTimes: safeTimes, // ✅ 서버 값 반영
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              const Text('위치',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: zone1LocationController,
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: '청주시 서원구 개신동 54, 충북빌라',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFF6B73FF)),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const MapScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );

                  if (result != null) {
                    print("✅ 지도에서 받은 데이터: $result");
                    setState(() {
                      safeZones[0] = {
                        "safeZoneName": zone1LocationController.text,
                        "latitude": result['latitude'],
                        "longitude": result['longitude'],
                        "radius": result['radius'],
                        "safeTimes": safeTimesForZone1,
                      };
                    });
                  }
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

          const SizedBox(height: 20),

          // 🕓 타임테이블 작성 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '시간 설정',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  // SharedPreferences or 서버에서 safeTimes 불러오기
                  final prefs = await SharedPreferences.getInstance();
                  final saved = prefs.getString('safeZoneTimes');
                  List<Map<String, dynamic>>? safeTimes;

                  if (saved != null) {
                    safeTimes = (jsonDecode(saved) as List)
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();
                    print("💾 불러온 safeTimes: $safeTimes");
                  } else {
                    print("ℹ️ 저장된 safeTimes 없음 — 새로 작성 모드");
                  }

                  // safeTimes 전달
                  final result =
                      await showModalBottomSheet<List<Map<String, dynamic>>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TimeTableModal(
                      safeZone: safeZone,
                      isEditing: true,
                      safeTimes: safeTimes,
                    ),
                  );

                  // 모달 닫힌 후 결과 반영
                  if (result != null) {
                    print('✅ ${safeZone} SafeTimes: $result');
                    setState(() {
                      safeTimesForZone1 = result;
                      safeZones[0]["safeTimes"] = result;
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3FF),
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
    zone1LocationController.dispose(); // ✅ 새로 추가한 컨트롤러 정리
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
  final List<Map<String, dynamic>>? safeTimes;

  const TimeTableModal({
    super.key,
    required this.safeZone,
    required this.isEditing,
    this.safeTimes,
  });

  @override
  State<TimeTableModal> createState() => _TimeTableModalState();
}

class _TimeTableModalState extends State<TimeTableModal> {
  final Set<String> selected = {};
  final List<String> days = ['일', '월', '화', '수', '목', '금', '토'];
  final List<int> times = List.generate(24, (index) => index + 1);

  @override
  void initState() {
    super.initState();

    // 서버에서 받은 safeTimes가 있을 경우 반영
    if (widget.safeTimes != null && widget.safeTimes!.isNotEmpty) {
      for (var item in widget.safeTimes!) {
        final dayIdx = _dayToIndex(item["daysActive"]);

        // "02:00:00" → 2, "05:00:00" → 5
        final start = int.parse(item["startTime"].toString().split(":")[0]);
        final end = int.parse(item["endTime"].toString().split(":")[0]);

        for (int hour = start; hour < end; hour++) {
          selected.add('$hour-$dayIdx');
        }
      }
      print('🟢 서버 safeTimes 반영 완료 (${selected.length}개 셀)');
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
