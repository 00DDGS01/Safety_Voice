import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:safety_voice/utils/secrets.dart';

Future<String> transcribeWithWhisper(File audioFile) async {
  final apiKey = '$openAiApiKey';
  final url = Uri.parse('https://api.openai.com/v1/audio/transcriptions');

  var request = http.MultipartRequest('POST', url)
    ..headers['Authorization'] = 'Bearer $apiKey'
    ..files.add(await http.MultipartFile.fromPath('file', audioFile.path))
    ..fields['language'] = 'ko'
    ..fields['model'] = 'whisper-1';

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  print('🔈 Whisper 응답 전체: ${response.body}'); // 여기 추가

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    print('📝 Whisper 텍스트: ${result['text']}'); // 실제 텍스트 필드만 출력
    return result['text'];
  } else {
    throw Exception('Whisper 오류: ${response.body}');
  }
}
