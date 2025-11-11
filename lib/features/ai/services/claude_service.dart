import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ClaudeService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiVersion = '2023-06-01';

  final String apiKey;
  final String model;

  ClaudeService({
    required this.apiKey,
    required this.model, // AppConfig에서 모델을 전달받도록 required로 변경
  });

  /// Claude API에 메시지를 전송하고 응답을 받습니다
  Future<String> sendMessage({
    required List<ChatMessage> messages,
    String? systemPrompt,
    int maxTokens = 1024,
    double temperature = 1.0,
  }) async {
    try {
      // API 요청 본문 구성
      final requestBody = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': messages
            .where((msg) => msg.role != MessageRole.system)
            .map((msg) => msg.toJson())
            .toList(),
      };

      // 시스템 프롬프트가 있으면 추가
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        requestBody['system'] = systemPrompt;
      }

      // API 요청
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode(requestBody),
      );

      // 응답 처리
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));

        // 토큰 사용량 로깅 (디버그용)
        if (responseData['usage'] != null) {
          final usage = responseData['usage'];
          print('📊 Token Usage:');
          print('  - Input tokens: ${usage['input_tokens']}');
          print('  - Output tokens: ${usage['output_tokens']}');
          print('  - Total: ${(usage['input_tokens'] ?? 0) + (usage['output_tokens'] ?? 0)}');
        }

        // Claude API 응답 형식: content는 배열이며, 텍스트는 첫 번째 요소에 있습니다
        if (responseData['content'] != null &&
            responseData['content'].isNotEmpty) {
          return responseData['content'][0]['text'] ?? '응답이 없습니다.';
        }

        return '응답이 없습니다.';
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
          'Claude API 오류 (${response.statusCode}): ${errorData['error']?['message'] ?? '알 수 없는 오류'}'
        );
      }
    } catch (e) {
      throw Exception('메시지 전송 실패: $e');
    }
  }

  /// 스트리밍 방식으로 응답을 받습니다 (실시간 타이핑 효과)
  Stream<String> sendMessageStream({
    required List<ChatMessage> messages,
    String? systemPrompt,
    int maxTokens = 1024,
    double temperature = 1.0,
  }) async* {
    try {
      final requestBody = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': messages
            .where((msg) => msg.role != MessageRole.system)
            .map((msg) => msg.toJson())
            .toList(),
        'stream': true,
      };

      // 시스템 프롬프트가 있으면 추가
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        requestBody['system'] = systemPrompt;
      }

      final request = http.Request('POST', Uri.parse(_apiUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
      });
      request.body = jsonEncode(requestBody);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // SSE (Server-Sent Events) 형식 파싱
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data.trim() == '[DONE]') continue;

              try {
                final json = jsonDecode(data);
                if (json['type'] == 'content_block_delta') {
                  final text = json['delta']?['text'];
                  if (text != null) {
                    yield text;
                  }
                }
              } catch (e) {
                // JSON 파싱 오류 무시
                continue;
              }
            }
          }
        }
      } else {
        throw Exception('스트림 응답 오류: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('스트리밍 메시지 전송 실패: $e');
    }
  }
}
