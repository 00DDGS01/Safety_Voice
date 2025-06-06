import 'dart:convert';
import 'dart:io';
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

  final decodedBody = utf8.decode(response.bodyBytes); // ✅ UTF-8로 디코딩
  print('🔈 Whisper 응답 전체: $decodedBody');

  if (response.statusCode == 200) {
    final result = jsonDecode(decodedBody); // ✅ 디코딩된 body로 파싱
    print('📝 Whisper 텍스트: ${result['text']}');
    return result['text'];
  } else {
    throw Exception('Whisper 오류: $decodedBody');
  }
}
