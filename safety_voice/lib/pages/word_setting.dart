import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'package:safety_voice/pages/home.dart';

import 'dart:async';
import 'dart:math';

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 본 화면
        Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90),
            child: AppBar(
              backgroundColor: const Color(0xFFEFF3FF),
              automaticallyImplyLeading: false,
              elevation: 0,
              flexibleSpace: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                              onPressed: () {
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
                              pageBuilder: (_, __, ___) =>
                                  const SetupScreen(),
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

        // ====== 전역 오버레이(네비/바텀 포함 전체 덮기) ======
        //if (isLearning) Positioned.fill(child: _buildLearningModal()),
      ],
    );
  }

  // // ==== 학습 제어 ====
  // void _startLearning() {
  //   setState(() {
  //     isLearning = true;
  //     learningStep = 1;
  //     learningStatus = "학습할 단어를 말해주세요";
  //   });

  //   _startWaveformAnimation();

  //   // 3초 후 말하기 단계
  //   Timer(const Duration(seconds: 3), () {
  //     if (isLearning) {
  //       setState(() {
  //         learningStep = 2;
  //         learningStatus = "말하는 중...";
  //       });
  //     }
  //   });

  //   // 6초 후 완료
  //   Timer(const Duration(seconds: 6), () {
  //     if (isLearning) {
  //       setState(() {
  //         isLearning = false;
  //         isLearningCompleted = true;
  //         learningStep = 1;
  //         learningStatus = "학습할 단어를 말해주세요";
  //       });
  //       _timer?.cancel();
  //     }
  //   });
  // }

  // void _stopLearning() {
  //   setState(() {
  //     isLearning = false;
  //     learningStep = 1;
  //     learningStatus = "학습할 단어를 말해주세요";
  //   });
  //   _timer?.cancel();
  // }

  // void _startWaveformAnimation() {
  //   _timer?.cancel();
  //   _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
  //     if (!isLearning) {
  //       timer.cancel();
  //       return;
  //     }
  //     setState(() {
  //       for (int i = 0; i < waveformData.length; i++) {
  //         if (learningStep == 1) {
  //           waveformData[i] = random.nextDouble() * 0.5 + 0.1;
  //         } else {
  //           waveformData[i] =
  //               (i < waveformData.length / 3)
  //                   ? random.nextDouble() * 0.8 + 0.2
  //                   : random.nextDouble() * 0.4 + 0.1;
  //         }
  //       }
  //     });
  //   });
  // }

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
                  color: isLearningCompleted ? Colors.green : const Color(0xFF6B73FF),
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
                      : () {
                          setState(() {
                            isLearning = true;
                            isLearningCompleted = false;
                            _progressValue = 0.0;
                          });

                          _progressTimer?.cancel();
                          _progressTimer =
                              Timer.periodic(const Duration(milliseconds: 200),
                                  (timer) {
                            setState(() {
                              _progressValue += 0.05;
                              if (_progressValue >= 1.0) {
                                _progressValue = 1.0;
                                isLearning = false;
                                isLearningCompleted = true;
                                timer.cancel();
                              }
                            });
                          });
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
                  onPressed: () {
                    _progressTimer?.cancel();
                    setState(() {
                      isLearning = false;
                      _progressValue = 0.0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    foregroundColor: const Color(0xFF6B73FF),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  Widget _buildEditWordSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          const Text(
            '녹음 단어',
            style:
                TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
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
                  fontSize: 16, color: Color(0xFF6B73FF), fontWeight: FontWeight.w600),
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
            style:
                TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
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
                  fontSize: 16, color: Color(0xFF6B73FF), fontWeight: FontWeight.w600),
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
                style:
                    TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
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
                      fontSize: 15, color: Color(0xFF6B73FF), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
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
                style:
                    TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Text(
                '2번',
                style:
                    TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
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
                      fontSize: 15, color: Color(0xFF6B73FF), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
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
                style:
                    TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w700),
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
                      fontSize: 15, color: Color(0xFF6B73FF), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
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
    super.dispose();
  }
}
