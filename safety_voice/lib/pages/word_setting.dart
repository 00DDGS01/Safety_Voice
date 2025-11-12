import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safety_voice/pages/setup_screen.dart';
import 'package:safety_voice/pages/home.dart';
import 'package:safety_voice/services/trigger_listener.dart';
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
  bool _isUserSettingLoaded = false;
  bool _settingsLoadedOnce = false;
  bool isEditing = false;
  bool isLearning = false;
  bool isRecording = false;
  bool isLearningCompleted = false;
  double _progressValue = 0.0;
  Timer? _progressTimer;

  double? _matchScore;
  bool? _isSamePerson;

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
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _loadUserSetting();
  }

  Future<void> _loadUserSettingOnce() async {
    if (_settingsLoadedOnce) return;
    _settingsLoadedOnce = true;
    await _loadUserSetting();
  }

  Future<void> _loadUserSetting() async {
    debugPrint('🔍 서버에서 사용자 설정 불러오기 시작');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      debugPrint('❌ JWT 토큰 없음 — 로그인 필요');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 후 이용 가능합니다.')),
        );
      }
      return;
    }

    final url = Uri.parse('https://safetyvoice.jp.ngrok.io/api/user/settings');

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json; charset=utf-8',
        },
      );

      // ✅ 응답 본문을 UTF-8로 강제 디코딩
      final utf8Body = utf8.decode(response.bodyBytes);
      debugPrint('📦 서버 응답 원문 (UTF-8): $utf8Body');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8Body);
        final data = jsonData['data'];

        await prefs.setString('trigger_word', data['triggerWord'] ?? '');
        await prefs.setString(
            'emergency_trigger_word', data['emergencyTriggerWord'] ?? '');
        await prefs.setBool(
            'is_voice_trained', data['isVoiceTrained'] ?? false);
        await prefs.setString(
            'emergency_contacts', jsonEncode(data['emergencyContacts'] ?? []));

        print("✅ SharedPreferences 서버 데이터로 갱신 완료");

        setState(() {
          wordController.text = data['triggerWord'] ?? '';
          emergencyWordController.text = data['emergencyTriggerWord'] ?? '';
          isLearningCompleted = data['isVoiceTrained'] ?? false;

          final contacts = data['emergencyContacts'] as List<dynamic>? ?? [];
          for (int i = 0;
              i < contacts.length && i < phoneControllers.length;
              i++) {
            phoneControllers[i].text = contacts[i]['phoneNumber'] ?? '';
          }

          _isUserSettingLoaded = true;
        });

        debugPrint('✅ 서버에서 사용자 설정 불러오기 성공');
      } else if (response.statusCode == 403) {
        debugPrint('❌ 인증 만료 — 다시 로그인 필요');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 인증이 만료되었습니다. 다시 로그인해주세요.')),
          );
        }
      } else {
        debugPrint('❌ 서버 오류: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ 서버 통신 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버에 연결할 수 없습니다.')),
        );
      }
    }
  }

  Future<void> _saveUserSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 이용 가능합니다.')),
      );
      return;
    }

    final url = Uri.parse('https://safetyvoice.jp.ngrok.io/api/user/settings');
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
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      // ✅ 응답 본문을 UTF-8로 강제 디코딩
      final utf8Body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(utf8Body);
      debugPrint('📦 서버 응답 원문 (UTF-8): $utf8Body');

      if (response.statusCode == 200) {
        debugPrint('✅ 서버에 사용자 설정 저장 완료');

        // ✅ SharedPreferences 갱신
        await prefs.setString('trigger_word', wordController.text.trim());
        await prefs.setString(
            'emergency_trigger_word', emergencyWordController.text.trim());

        // ✅ STT 단어 갱신
        await TriggerListener.instance.refreshWords();

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
        debugPrint('❌ 서버 오류: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 오류: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ 요청 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버에 연결할 수 없습니다.')),
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
                          const SizedBox(height: 25),
                          _buildVoiceTestingSection(),
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
                                        onPressed: () {
                                          Navigator.pop(
                                              context, false); // ✅ 모달만 닫기
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color.fromARGB(
                                              255, 65, 65, 65),
                                        ),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _saveUserSetting();
                                          setState(() => isEditing = false);
                                          Navigator.pop(context, true); // ✅ 닫기
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  const Text('설정값이 수정되었습니다.'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              duration:
                                                  const Duration(seconds: 2),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                            ),
                                          );
                                        },
                                        child: const Text('수정'),
                                      ),
                                    ],
                                  ),
                                );
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
                          )
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

  Future<void> _stopLearningRecording(
      {bool save = true, bool showToast = true}) async {
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

          // ✅ showToast=true일 때만 스낵바 표시
          if (showToast && context.mounted && path != null) {
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

  // FastAPI 업로드 함수
  Future<void> _uploadToFastAPI(String filePath) async {
    final uri = Uri.parse("https://fastapi.jp.ngrok.io/voice/train");
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      print("✅ FastAPI 업로드 성공");
    } else {
      print("❌ FastAPI 업로드 실패 (${response.statusCode})");
    }
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

                                // FastAPI
                                if (_lastLearningFilePath != null) {
                                  await _uploadToFastAPI(
                                      _lastLearningFilePath!);
                                }
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

  Widget _buildVoiceTestingSection() {
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
                "목소리 유사도를 측정해보세요!",
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
                : (isLearningCompleted ? "" : "저장된 목소리와 다르면 유사도가 떨어집니다."),
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
                                await _stopLearningRecording(
                                    save: true, showToast: false);

                                if (!mounted) return;
                                setState(() {
                                  isLearning = false;
                                  isLearningCompleted = true;
                                });

                                if (_progressValue >= 1.0) {
                                  timer.cancel();

                                  // 🔵 녹음 저장(정지)
                                  await _stopLearningRecording(save: true);

                                  if (!mounted) return;
                                  setState(() {
                                    isLearning = false;
                                    isLearningCompleted = true;
                                  });

                                  // ✅ FastAPI 유사도 검사 호출
                                  if (_lastLearningFilePath != null) {
                                    await _verifyWithFastAPI(
                                        _lastLearningFilePath!);
                                  }
                                }
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
                        ? "녹음 중..."
                        : (isLearningCompleted ? "다시 녹음하기" : "녹음 시작"),
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
          // ✅ 🔽 여기 추가! — 유사도 결과 표시 블록
          if (_matchScore != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "유사도: ${(_matchScore! * 100).toStringAsFixed(2)}%",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _isSamePerson == true ? "✅ 같은 사람" : "⚠️ 다른 사람",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isSamePerson == true
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _verifyWithFastAPI(String filePath) async {
    final uri = Uri.parse("https://fastapi.jp.ngrok.io/voice/verify");
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      final score = data['match_score'];
      final shouldRecord = data['should_record'];

      print("✅ 유사도 검사 성공: $score (${shouldRecord ? "같은 사람" : "다른 사람"})");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("유사도: ${(score * 100).toStringAsFixed(2)}%")),
        );
      }
    } else {
      print("❌ 유사도 검사 실패 (${response.statusCode})");
      print("Response: $responseBody");
    }
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
