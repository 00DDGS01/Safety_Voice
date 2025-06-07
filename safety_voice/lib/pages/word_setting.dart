
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'dart:async';
import 'dart:math';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final int learningStep;
  
  WaveformPainter({required this.amplitudes, this.learningStep = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final purplePaint = Paint()
      ..color = Color(0xFF8B80F8)  // 보라색
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final greyPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)  // 회색
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final barWidth = (width / amplitudes.length) * 0.6; // 막대 사이 간격을 위해 0.6 곱함
    final spacing = (width / amplitudes.length) * 0.4;  // 막대 사이 간격
    
    for (var i = 0; i < amplitudes.length; i++) {
      final x = i * (barWidth + spacing);
      final centerY = height / 2;
      final barHeight = amplitudes[i] * height * 0.7;  // 전체 높이의 70%만 사용
      
      // 학습 단계에 따라 색상 결정
      Paint paint;
      if (learningStep == 1) {
        // 첫 번째 단계: 모든 막대가 회색
        paint = greyPaint;
      } else {
        // 두 번째 단계: 처음 1/3은 보라색, 나머지는 회색
        paint = i < amplitudes.length / 3 ? purplePaint : greyPaint;
      }
      
      canvas.drawLine(
        Offset(x + barWidth/2, centerY - barHeight / 2),
        Offset(x + barWidth/2, centerY + barHeight / 2),
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
  List<double> amplitudes = List.filled(30, 0.0);
  Timer? _timer;
  List<double> waveformData = List.filled(50, 0.0);
  String learningStatus = "학습할 단어를 말해주세요";
  int learningStep = 1; // 1: 첫 번째 단계, 2: 두 번째 단계
  Random random = Random();

  final TextEditingController wordController = TextEditingController(text: '잠만');
  final TextEditingController recordSecondsController = TextEditingController(text: '2');
  final TextEditingController recordCountController = TextEditingController(text: '3');
  final TextEditingController emergencySecondsController = TextEditingController(text: '4');
  final TextEditingController emergencyCountController = TextEditingController(text: '5');
  final List<TextEditingController> phoneControllers = List.generate(
    3,
    (index) => TextEditingController(
      text: index == 0 ? '112' : '010-1234-5678',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: Color(0xFFEFF3FF),
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isEditing) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() => isEditing = false);
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    Expanded(
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
                    SizedBox(width: 24), // 뒤로가기 버튼과 균형 맞추기
                  ] else ...[
                    // 가운데 정렬을 위해 Expanded로 감싸기
                    Expanded(
                      child: Text(
                        '사용자의 설정 현황',
                        textAlign: TextAlign.center, // 가운데 정렬 추가
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => isEditing = true);
                      },
                      child: Text(
                        '수정',
                        style: TextStyle(
                          color: Color(0xFF6B73FF),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
                          _buildViewWordSection(),
                          SizedBox(height: 32),
                          _buildViewRecordingSection(),
                          SizedBox(height: 32),
                          _buildViewEmergencySection(),
                          SizedBox(height: 48),
                          _buildViewContactSection(),
                        ] else ...[
                          // 편집 모드
                          _buildEditWordSection(),
                          SizedBox(height: 20),
                          _buildEditRecordingSection(),
                          SizedBox(height: 20),
                          _buildEditEmergencySection(),
                          SizedBox(height: 30),
                          _buildEditContactSection(),
                          SizedBox(height: 40),
                          // 설정값 수정하기 버튼
                          Container(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => isEditing = false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6B73FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
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
          if (isLearning) _buildLearningModal(),
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
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/calendarhome'),
                    child: Image.asset(
                      'assets/home/recordingList.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/safezone'),
                    child: Image.asset(
                      'assets/home/wordRecognition_.png',
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

  // 학습 시작
  void _startLearning() {
    setState(() {
      isLearning = true;
      learningStep = 1;
      learningStatus = "학습할 단어를 말해주세요";
    });
    
    // 웨이브폼 애니메이션 시작
    _startWaveformAnimation();
    
    // 3초 후 두 번째 단계로 전환
    Timer(Duration(seconds: 3), () {
      if (isLearning) {
        setState(() {
          learningStep = 2;
          learningStatus = "말하는 중...";
        });
      }
    });
    
    // 6초 후 학습 완료
    Timer(Duration(seconds: 6), () {
      if (isLearning) {
        setState(() {
          isLearning = false;
          isLearningCompleted = true;
          learningStep = 1;
          learningStatus = "학습할 단어를 말해주세요";
        });
        _timer?.cancel();
      }
    });
  }

  // 학습 중지
  void _stopLearning() {
    setState(() {
      isLearning = false;
      learningStep = 1;
      learningStatus = "학습할 단어를 말해주세요";
    });
    _timer?.cancel();
  }

  // 웨이브폼 애니메이션 시작
  void _startWaveformAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!isLearning) {
        timer.cancel();
        return;
      }
      
      setState(() {
        for (int i = 0; i < waveformData.length; i++) {
          if (learningStep == 1) {
            // 첫 번째 단계: 회색 웨이브폼
            waveformData[i] = random.nextDouble() * 0.5 + 0.1;
          } else {
            // 두 번째 단계: 보라색과 회색 혼합 웨이브폼
            if (i < waveformData.length / 3) {
              waveformData[i] = random.nextDouble() * 0.8 + 0.2;
            } else {
              waveformData[i] = random.nextDouble() * 0.4 + 0.1;
            }
          }
        }
      });
    });
  }

  Widget _buildEditRecordingSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '녹음 횟수',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Container(
                width: 40,
                height: 40,
                child: TextField(
                  controller: recordSecondsController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text('초 안에', style: TextStyle(fontSize: 20, color: Colors.black,   fontWeight: FontWeight.w700)),
              SizedBox(width: 22),
              Container(
                width: 40,
                height: 40,
                child: TextField(
                  controller: recordCountController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              SizedBox(width: 5),
              Text('회', style: TextStyle(fontSize: 20, color: Colors.black ,  fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  // 학습 모달 위젯 (정사각형으로 변경)
  Widget _buildLearningModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 350, // 고정 너비
          height: 350, // 고정 높이 (정사각형)
          margin: EdgeInsets.symmetric(horizontal: 30),
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 닫기 버튼 (상단 우측)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _stopLearning,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              
              // 마이크 아이콘 (빨간 원형 배경)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.red.withOpacity(0.9),
                      Colors.red.withOpacity(0.4),
                      Colors.red.withOpacity(0.2),
                      Colors.red.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: [0.2, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.mic,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              // 웨이브폼
              Container(
                height: 60,
                width: double.infinity,
                child: CustomPaint(
                  painter: WaveformPainter(
                    amplitudes: waveformData,
                    learningStep: learningStep,
                  ),
                  size: Size(double.infinity, 60),
                ),
              ),
              SizedBox(height: 30),
              
              // 상태 텍스트
              Text(
                learningStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 일반 보기 모드 위젯들
  Widget _buildViewWordSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Text(
            '현재 단어',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 80, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFE8EAFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              wordController.text,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B73FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewRecordingSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Text(
            '녹음 횟수',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recordSecondsController.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text('초 안에', style: TextStyle(fontSize: 20, color: Colors.black,fontWeight: FontWeight.w700)),
              SizedBox(width: 22),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recordCountController.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 5),
              Text('회', style: TextStyle(fontSize: 20, color: Colors.black,fontWeight: FontWeight.w700,)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewEmergencySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Text(
            '비상 연락 횟수',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emergencySecondsController.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text('초 안에', style: TextStyle(fontSize: 20, color: Colors.black,fontWeight: FontWeight.w700)),
              SizedBox(width: 22),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical:10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emergencyCountController.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 5),
              Text('회', style: TextStyle(fontSize: 20, color: Colors.black,fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1번 - 첫 번째 줄 (1번 + 112)
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 0),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Spacer(),
              Text(
                '1번',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 160,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    phoneControllers[0].text,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 2번 - 두 번째 줄 (비상 연락망 + 2번 + 전화번호)
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 0),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Text(
                '비상 연락망',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                '2번',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width:10),
              Container(
                width: 160,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    phoneControllers[1].text,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 3번 - 세 번째 줄 (3번 + 전화번호)
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Spacer(),
              Text(
                '3번',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 160,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFE8EAFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    phoneControllers[2].text,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 편집 모드 위젯들
  Widget _buildEditWordSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '현재 단어',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Container(
                width: 190,
                height: 40,
                child: TextField(
                  controller: wordController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '잠만',
                    hintStyle: TextStyle(color: Color(0xFF6B73FF).withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                _startLearning();
              },
              child: Text(
                isLearning ? '학습중' : (isLearningCompleted ? '학습완료!' : '학습하기 >'),
                style: TextStyle(
                  fontSize: 14,
                  color: isLearning ? Colors.green : (isLearningCompleted ? Colors.blue : Colors.red),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditEmergencySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '비상 연락 횟수',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Container(
                width: 40,
                height: 40,
                child: TextField(
                  controller: emergencySecondsController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text('초 안에', style: TextStyle(fontSize: 20, color: Colors.black,  fontWeight: FontWeight.w700)),
              SizedBox(width: 22),
              Container(
                width: 40,
                height: 40,
                child: TextField(
                  controller: emergencyCountController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              SizedBox(width: 5),
              Text('회', style: TextStyle(fontSize: 20, color: Colors.black,  fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1번 - 첫 번째 줄 (1번 + 112 입력필드)
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 0),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Spacer(),
              Text(
                '1번',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 160,
                height: 40,
                child: TextField(
                  controller: phoneControllers[0],
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 2번 - 두 번째 줄 (비상 연락망 + 2번 + 전화번호 입력필드)
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 0),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Text(
                '비상 연락망',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                '2번',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              
              Container(
                width: 160,
                height: 40,
                child: TextField(
                  controller: phoneControllers[1],
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 3번 - 세 번째 줄 (3번 + 전화번호 입력필드)
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Spacer(),
              Text(
                '3번',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 160,
                height: 40,
                child: TextField(
                  controller: phoneControllers[2],
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B73FF),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF6B73FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    for (var controller in phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}