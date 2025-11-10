import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'package:safety_voice/pages/home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:safety_voice/pages/hint.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final int learningStep;

  WaveformPainter({required this.amplitudes, this.learningStep = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final purplePaint = Paint()
      ..color = const Color(0xFF8B80F8)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final greyPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final barWidth = (width / amplitudes.length) * 0.6;
    final spacing = (width / amplitudes.length) * 0.4;

    for (var i = 0; i < amplitudes.length; i++) {
      final x = i * (barWidth + spacing);
      final centerY = height / 2;
      final barHeight = amplitudes[i] * height * 0.7;

      // 단계별 색상
      final paint = (learningStep == 1)
          ? greyPaint
          : (i < amplitudes.length / 3 ? purplePaint : greyPaint);

      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - barHeight / 2),
        Offset(x + barWidth / 2, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isEditing = false;
  bool isLearning = false;
  bool isRecording = false;
  bool isLearningCompleted = false;
  double _progressValue = 0.0;
  Timer? _progressTimer;

  Timer? _timer;
  List<double> waveformData = List.filled(50, 0.0);
  int learningStep = 1; // 1: 준비, 2: 말하기
  String learningStatus = "학습할 단어를 말해주세요";
  final Random random = Random();
  final AudioRecorder _recorder = AudioRecorder();
  String? _lastLearningFilePath;

  final TextEditingController wordController =
      TextEditingController(text: '정리하자면');
  final TextEditingController emergencyWordController =
      TextEditingController(text: '잠시만요');
  final TextEditingController recordSecondsController =
      TextEditingController(text: '2');
  final TextEditingController recordCountController =
      TextEditingController(text: '3');
  final TextEditingController emergencySecondsController =
      TextEditingController(text: '4');
  final TextEditingController emergencyCountController =
      TextEditingController(text: '5');

  final List<TextEditingController> phoneControllers = List.generate(
    3,
    (index) => TextEditingController(
      text: index == 0 ? '112' : '010-1234-5678',
    ),
  );

  Future<void> _saveUserSetting() async {
    final url = Uri.parse('http://192.168.0.102:8080/api/user/settings');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 이용 가능합니다.')),
      );
      return;
    }

    final body = {
      "triggerWord": wordController.text,
      "emergencyTriggerWord": emergencyWordController.text,
      "isVoiceTrained": isLearningCompleted,
      "emergencyContacts": phoneControllers
          .where((controller) => controller.text.isNotEmpty)
          .map((controller) => {
                "name": "연락처",
                "phoneNumber": controller.text,
              })
          .toList(),
    };

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('설정이 성공적으로 저장되었습니다.')),
          );
        }
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 인증이 만료되었습니다. 다시 로그인해주세요.')),
        );
      } else {
        debugPrint("❌ 서버 응답 오류: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 오류: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint("⚠️ 요청 실패: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버에 연결할 수 없습니다.')),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 본 화면
        Scaffold(
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
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        if (!isEditing) ...[
                          _buildViewWordSection(),
                          const SizedBox(height: 25),
                          _buildViewEmergencyWordSection(),
                          const SizedBox(height: 25),
                          _buildViewContactSection(),
                        ] else ...[
                          _buildVoiceLearningSection(),
                          const SizedBox(height: 20),
                          _buildEditWordSection(),
                          const SizedBox(height: 20),
                          _buildEditEmergencyWordSection(),
                          const SizedBox(height: 20),
                          _buildEditContactSection(),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!mounted) return;

                                // 먼저 다이얼로그 띄우기
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    content: const Text('정말로 설정값을 수정하시겠습니까?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: const Color.fromARGB(
                                              255, 65, 65, 65),
                                        ),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: const Color.fromARGB(
                                              255, 65, 65, 65),
                                        ),
                                        child: const Text('수정'),
                                      ),
                                    ],
                                  ),
                                );
                                // 사용자가 확인 눌렀을 때만 실행
                                if (confirmed == true) {
                                  setState(() => isEditing = false);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('설정값이 수정되었습니다.'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                    ),
                                  );
                                }

                                await _saveUserSetting();
                                setState(() => isEditing = false);
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
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SizedBox(
            height: 80,
            child: Material(
              elevation: 20,
              color: const Color.fromARGB(157, 0, 0, 0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  border: Border(
                    top: BorderSide(
                      color: Color.fromARGB(255, 177, 177, 177),
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
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Image.asset('assets/home/wordRecognition_.png',
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
        ),
      ],
    );
  }

//----------------학습 시작 버튼 녹음-----------------

  Future<void> _startLearningRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('마이크 권한이 필요합니다. 설정에서 허용해주세요.')),
          );
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
      final safeWord =
          wordController.text.replaceAll(RegExp(r'[^ㄱ-힣a-zA-Z0-9_-]'), '_');
      final path = '${dir.path}/learning_${safeWord}_$ts.m4a';

      // 시작
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 1, // 필요시
        ),
        path: path,
      );
      _lastLearningFilePath = path;
      debugPrint('🎙️ 학습 녹음 시작: $path');
    } catch (e) {
      debugPrint('녹음 시작 실패: $e');
    }
  }

  Future<void> _stopLearningRecording({bool save = true}) async {
    try {
      if (await _recorder.isRecording()) {
        final path = await _recorder.stop(); // 실제 저장 경로 반환
        debugPrint('🛑 학습 녹음 중지: $path');

        // 취소 시 파일 삭제
        if (!save && path != null) {
          final f = File(path);
          if (await f.exists()) {
            await f.delete();
            debugPrint('❌ 취소로 파일 삭제: $path');
          }
          _lastLearningFilePath = null;
        } else {
          _lastLearningFilePath = path;
          if (context.mounted && path != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('학습 음성 저장 완료\n$path')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('녹음 중지 실패: $e');
    }
  }

  // (선택) 나중에 FastAPI로 업로드할 훅
  Future<void> _uploadToFastAPI(String filePath) async {
    // TODO: dio/http로 multipart 업로드 구현
    // final url = 'http://<fastapi-host>/train';
    // FormData에 file 붙여서 POST
    debugPrint('⬆️ 업로드 예정 파일: $filePath');
  }

//-----녹음 끝---------------------

  // 편집 모드에서만 쓰는 학습하기 카드
  Widget _buildVoiceLearningSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isLearningCompleted
                      ? Colors.green
                      : const Color(0xFF6B73FF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "목소리 학습하기",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLearning
                ? "마이크에 대고 평소 말투로 천천히 말해주세요."
                : (isLearningCompleted
                    ? "학습이 완료되었습니다. 필요하면 다시 학습할 수 있어요."
                    : "사용자의 고유 목소리를 학습해 정확도와 보안을 높입니다."),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (isLearning) ...[
            LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: Colors.grey[300],
              color: const Color(0xFF6B73FF),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLearning
                      ? null
                      : () async {
                          // 시작 상태로 전환
                          setState(() {
                            isLearning = true;
                            isLearningCompleted = false;
                            _progressValue = 0.0;
                          });

                          // 🔴 실제 녹음 시작
                          await _startLearningRecording();

                          // 진행바 타이머 시작
                          _progressTimer?.cancel();
                          _progressTimer = Timer.periodic(
                            const Duration(milliseconds: 200),
                            (timer) async {
                              if (!mounted) return;

                              setState(() {
                                _progressValue += 0.05; // 약 4초
                                if (_progressValue >= 1.0) {
                                  _progressValue = 1.0;
                                }
                              });

                              // 완료 시점
                              if (_progressValue >= 1.0) {
                                timer.cancel();

                                // 🔵 녹음 저장(정지)
                                await _stopLearningRecording(save: true);

                                if (!mounted) return;
                                setState(() {
                                  isLearning = false;
                                  isLearningCompleted = true;
                                });

                                // (선택) FastAPI 업로드 훅
                                // if (_lastLearningFilePath != null) {
                                //   await _uploadToFastAPI(_lastLearningFilePath!);
                                // }
                              }
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B73FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.mic, size: 20),
                  label: Text(
                    isLearning
                        ? "학습 중..."
                        : (isLearningCompleted ? "다시 학습하기" : "학습 시작"),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (isLearning) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    // 진행바 중단
                    _progressTimer?.cancel();
                    // 🟡 사용자 취소 → 파일 삭제
                    await _stopLearningRecording(save: false);

                    if (!mounted) return;
                    setState(() {
                      isLearning = false;
                      _progressValue = 0.0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    foregroundColor: const Color(0xFF6B73FF),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("중지"),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==== 학습 모달 ====
  // Widget _buildLearningModal() {
  //   return Stack(
  //     children: [
  //       const ModalBarrier(color: Colors.black54, dismissible: false),
  //       Center(
  //         child: Material(
  //           type: MaterialType.transparency,
  //           child: Container(
  //             width: 350,
  //             height: 350,
  //             margin: const EdgeInsets.symmetric(horizontal: 30),
  //             padding: const EdgeInsets.all(30),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(20),
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 // 닫기
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.end,
  //                   children: [
  //                     GestureDetector(
  //                       onTap: _stopLearning,
  //                       child: Container(
  //                         width: 30,
  //                         height: 30,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[300],
  //                           shape: BoxShape.circle,
  //                         ),
  //                         child: Icon(Icons.close,
  //                             color: Colors.grey[600], size: 20),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 10),

  //                 // 마이크
  //                 Container(
  //                   width: 100,
  //                   height: 100,
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     gradient: RadialGradient(
  //                       colors: [
  //                         Colors.red.withOpacity(0.9),
  //                         Colors.red.withOpacity(0.4),
  //                         Colors.red.withOpacity(0.2),
  //                         Colors.red.withOpacity(0.05),
  //                         Colors.transparent,
  //                       ],
  //                       stops: const [0.2, 0.4, 0.6, 0.8, 1.0],
  //                     ),
  //                   ),
  //                   child: const Center(
  //                     child: Icon(Icons.mic, size: 45, color: Colors.white),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 30),

  //                 // 웨이브폼
  //                 SizedBox(
  //                   height: 60,
  //                   width: double.infinity,
  //                   child: CustomPaint(
  //                     painter: WaveformPainter(
  //                       amplitudes: waveformData,
  //                       learningStep: learningStep,
  //                     ),
  //                     size: const Size(double.infinity, 60),
  //                   ),
  //                 ),

  //                 // 상태 텍스트
  //                 Text(
  //                   learningStatus,
  //                   textAlign: TextAlign.center,
  //                   style: const TextStyle(
  //                     fontSize: 15,
  //                     color: Colors.black,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ==== 공통 UI ====
  Widget _scrollablePill(
    String text, {
    double width = 150,
    double height = 40,
    EdgeInsetsGeometry? innerPadding,
    Color bg = const Color(0xFFE8EAFF),
    TextStyle style = const TextStyle(
      fontSize: 15,
      color: Color(0xFF6B73FF),
      fontWeight: FontWeight.w600,
    ),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: innerPadding ??
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                text,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: style,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==== View 모드 섹션 ====
  Widget _buildViewWordSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          const Text(
            '녹음 단어',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _scrollablePill(
            wordController.text,
            width: 150,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildViewEmergencyWordSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          const Text(
            '비상 연락 단어',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _scrollablePill(
            emergencyWordController.text,
            width: 150,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildViewContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1번
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 0),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              const Spacer(),
              const Text(
                '1번',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              _scrollablePill(
                phoneControllers[0].text,
                width: 160,
                height: 40,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B73FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // 2번
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 0),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              const Text(
                '비상 연락망',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Text(
                '2번',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              _scrollablePill(
                phoneControllers[1].text,
                width: 160,
                height: 40,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B73FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // 3번
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              const Spacer(),
              const Text(
                '3번',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              _scrollablePill(
                phoneControllers[2].text,
                width: 160,
                height: 40,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B73FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==== Edit 모드 섹션 ====
  InputDecoration _inputDeco({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF6B73FF),
      ).copyWith(color: const Color(0xFF6B73FF).withOpacity(0.5)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  Widget _buildEditWordSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          const Text(
            '녹음 단어',
            style: TextStyle(
                fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          SizedBox(
            width: 160,
            height: 40,
            child: TextField(
              controller: wordController,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B73FF),
                  fontWeight: FontWeight.w600),
              decoration: _inputDeco(hint: '정리하자면'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditEmergencyWordSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          const Text(
            '비상 연락 단어',
            style: TextStyle(
                fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          SizedBox(
            width: 160,
            height: 40,
            child: TextField(
              controller: emergencyWordController,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B73FF),
                  fontWeight: FontWeight.w600),
              decoration: _inputDeco(hint: '잠시만요'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1번
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Spacer(),
              const Text(
                '1번',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 160,
                height: 45,
                child: TextField(
                  controller: phoneControllers[0],
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 2번
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Text(
                '비상 연락망',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Text(
                '2번',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 160,
                height: 45,
                child: TextField(
                  controller: phoneControllers[1],
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 3번
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Spacer(),
              const Text(
                '3번',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 160,
                height: 45,
                child: TextField(
                  controller: phoneControllers[2],
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    wordController.dispose();
    recordSecondsController.dispose();
    recordCountController.dispose();
    emergencySecondsController.dispose();
    emergencyCountController.dispose();
    _timer?.cancel();
    for (var c in phoneControllers) {
      c.dispose();
    }
    _recorder.dispose();
    super.dispose();
  }
}
