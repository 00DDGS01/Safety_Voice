import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:safety_voice/utils/secrets.dart';

Future<String> transcribeWithWhisper(File audioFile) async {

  final apiKey = '$openAiApiKey';
  final url = Uri.parse('https://api.openai.com/v1/audio/transcriptions');

  var request = http.MultipartRequest('POST', url)
    ..headers['Authorization'] = 'Bearer $apiKey'
    ..files.add(await http.MultipartFile.fromPath('file', audioFile.path))
    ..fields['model'] = 'whisper-1';

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    return response.body; // 또는 jsonDecode(response.body)['text']
  } else {
    throw Exception('Whisper 오류: ${response.body}');
  }
}

