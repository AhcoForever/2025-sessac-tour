import 'dart:convert';
import '../models/chat_message.dart';
import '../models/recommendation.dart';
import '../services/claude_service.dart';

/// 채팅 메시지 전송 및 응답 처리를 담당하는 클래스
class ChatMessageHandler {
  final ClaudeService claudeService;
  final List<ChatMessage> messages = [];

  bool _isLoading = false;

  // 상수 정의
  static const int maxMessageCount = 100; // 최대 메시지 개수 (메모리 누수 방지)
  static const int recentMessageLimit = 10; // API 전송 시 최근 메시지 제한

  // Getters
  bool get isLoading => _isLoading;
  int get messageCount => messages.length;

  ChatMessageHandler({required this.claudeService});

  /// 초기 환영 메시지 추가
  void addWelcomeMessage(String message) {
    messages.add(ChatMessage.assistant(message));
  }

  /// 사용자 메시지 추가
  void addUserMessage(String text) {
    messages.add(ChatMessage.user(text));
    _trimMessagesIfNeeded();
  }

  /// 메시지 개수 제한 (메모리 누수 방지)
  /// 최대 개수를 넘으면 오래된 메시지부터 삭제 (환영 메시지는 유지)
  void _trimMessagesIfNeeded() {
    if (messages.length > maxMessageCount) {
      final welcomeMessage = messages.firstOrNull;
      final excessCount = messages.length - maxMessageCount;

      // 환영 메시지가 있으면 두 번째 메시지부터 삭제
      if (welcomeMessage != null) {
        messages.removeRange(1, 1 + excessCount);
        print('📝 메시지 정리: ${excessCount}개 삭제 (현재: ${messages.length}개)');
      } else {
        messages.removeRange(0, excessCount);
        print('📝 메시지 정리: ${excessCount}개 삭제 (현재: ${messages.length}개)');
      }
    }
  }

  /// 메시지 전송 (스트리밍)
  Stream<ChatStreamEvent> sendMessage({
    required String userMessage,
    required String systemPrompt,
    int maxTokens = 2048,
  }) async* {
    _isLoading = true;

    // 사용자 메시지 추가
    addUserMessage(userMessage);
    yield ChatStreamEvent.messageAdded();

    // 빈 Assistant 메시지 추가
    final assistantMessage = ChatMessage.assistant('');
    messages.add(assistantMessage);
    yield ChatStreamEvent.messageAdded();

    String accumulatedText = '';

    try {
      // 토큰 절약: 최근 N개 메시지만 전송
      final messagesToSend = messages.where((msg) => msg != assistantMessage).toList();
      final recentMessages = messagesToSend.length > recentMessageLimit
          ? messagesToSend.sublist(messagesToSend.length - recentMessageLimit)
          : messagesToSend;

      print('💬 메시지 전송: ${messagesToSend.length}개 → ${recentMessages.length}개 (최근 ${recentMessageLimit}개로 제한)');

      // Claude API 스트리밍 호출
      final stream = claudeService.sendMessageStream(
        messages: recentMessages,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
      );

      await for (var chunk in stream) {
        accumulatedText += chunk;

        // 실시간 텍스트 업데이트
        messages[messages.length - 1] = ChatMessage.assistant(accumulatedText);
        yield ChatStreamEvent.textUpdate(accumulatedText);
      }

      // 스트리밍 완료 후 추천 데이터 파싱
      final (textPart, recommendations) = _parseResponse(accumulatedText);

      // 최종 메시지 업데이트
      messages[messages.length - 1] = ChatMessage.assistant(
        textPart,
        recommendations: recommendations,
      );

      _isLoading = false;
      yield ChatStreamEvent.completed(textPart, recommendations);
    } catch (e) {
      // 오류 처리
      messages[messages.length - 1] = ChatMessage.assistant(
        '죄송합니다. 오류가 발생했습니다: ${e.toString()}',
      );

      _isLoading = false;
      yield ChatStreamEvent.error(e.toString());
    }
  }

  /// Claude 응답에서 추천 데이터 파싱
  ///
  /// 응답 형식: 텍스트 + [RECOMMENDATIONS]JSON[/RECOMMENDATIONS]
  /// 반환: (텍스트 부분, 추천 리스트)
  (String, List<Recommendation>?) _parseResponse(String response) {
    // [RECOMMENDATIONS]...[/RECOMMENDATIONS] 태그 찾기
    const startTag = '[RECOMMENDATIONS]';
    const endTag = '[/RECOMMENDATIONS]';

    final startIndex = response.indexOf(startTag);
    final endIndex = response.indexOf(endTag);

    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      // 추천 데이터가 없으면 원본 응답 그대로 반환
      return (response, null);
    }

    // 텍스트 부분 추출 (추천 JSON 제외)
    final textPart = response.substring(0, startIndex).trim();

    // JSON 부분 추출
    final jsonPart = response.substring(
      startIndex + startTag.length,
      endIndex,
    ).trim();

    try {
      // JSON 파싱
      final jsonData = jsonDecode(jsonPart) as Map<String, dynamic>;
      final recommendationsJson = jsonData['recommendations'] as List<dynamic>;

      // Recommendation 객체 리스트로 변환
      final recommendations = recommendationsJson
          .map((json) => Recommendation.fromJson(json as Map<String, dynamic>))
          .toList();

      return (textPart, recommendations);
    } catch (e) {
      print('❌ 추천 JSON 파싱 실패: $e');
      print('JSON: $jsonPart');
      // 파싱 실패 시 원본 응답 반환
      return (response, null);
    }
  }

  /// 최근 메시지 가져오기
  ChatMessage? getLastMessage() {
    return messages.isNotEmpty ? messages.last : null;
  }

  /// 메시지 초기화
  void clearMessages() {
    messages.clear();
  }
}

/// 채팅 스트림 이벤트
sealed class ChatStreamEvent {
  const ChatStreamEvent();

  factory ChatStreamEvent.messageAdded() = MessageAdded;
  factory ChatStreamEvent.textUpdate(String text) = TextUpdate;
  factory ChatStreamEvent.completed(String text, List<Recommendation>? recommendations) = Completed;
  factory ChatStreamEvent.error(String error) = ErrorOccurred;
}

class MessageAdded extends ChatStreamEvent {
  const MessageAdded();
}

class TextUpdate extends ChatStreamEvent {
  final String text;
  const TextUpdate(this.text);
}

class Completed extends ChatStreamEvent {
  final String text;
  final List<Recommendation>? recommendations;
  const Completed(this.text, this.recommendations);
}

class ErrorOccurred extends ChatStreamEvent {
  final String error;
  const ErrorOccurred(this.error);
}
