import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safety_voice/utils/secrets.dart';

Future<String> summarizeWithGPT(String transcript) async {
  final apiKey = '$openAiApiKey';
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'gpt-4',
      'messages': [
        {'role': 'system', 'content': '다음 텍스트를 간결하게 요약해줘.'},
        {'role': 'user', 'content': transcript},
      ],
    }),
  );

  final decodedBody = utf8.decode(response.bodyBytes); // ✅ 디코딩
  print('📩 GPT 응답 원문: $decodedBody');

  if (response.statusCode == 200) {
    final data = jsonDecode(decodedBody); // ✅ 디코딩된 문자열로 JSON 파싱
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception('GPT 오류: $decodedBody');
  }
}
