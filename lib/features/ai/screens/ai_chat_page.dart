import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config.dart';
import '../../public_data/models/cultural_event.dart';
import '../../public_data/models/content_list_item.dart';
import '../../public_data/services/seoulapi_service.dart';
import '../../public_data/services/visitseoul_api_service.dart';
import '../models/chat_message.dart';
import '../models/chracter.dart';
import '../services/claude_service.dart';
import '../services/character_storage_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late ClaudeService _claudeService;
  final SeoulApiService _seoulApiService = SeoulApiService();
  final VisitSeoulApiService _visitSeoulApiService = VisitSeoulApiService();

  bool _isLoading = false;
  bool _isLoadingData = true; // 데이터 로딩 중
  List<CulturalEvent> _culturalEvents = [];
  String _eventsDataText = '';
  List<ContentListItem> _tourContents = [];
  String _tourContentsDataText = '';
  Character? _selectedCharacter; // 선택된 캐릭터

  // 🎯 시스템 프롬프트 (선택된 캐릭터 기반)
  String get _systemPrompt {
    String characterPrompt = '';

    if (_selectedCharacter != null) {
      // 선택된 캐릭터의 프롬프트 사용
      characterPrompt = _selectedCharacter!.getSystemPrompt();
    } else {
      // 기본 프롬프트 (폴백)
      characterPrompt = '''
당신은 "소울해치"라는 이름의 친근한 서울 여행 가이드입니다.

역할:
- 사용자의 기분과 상황을 파악하여 서울의 명소, 맛집, 문화 이벤트를 추천합니다
- 친근하고 따뜻한 말투로 대화합니다
- 이모지를 적절히 사용하여 생동감 있게 표현합니다

말투 특징:
- "~야", "~해" 등 반말을 사용합니다
- 공감하고 격려하는 톤으로 대화합니다
- 예: "오늘 기분이 어때?", "그렇구나! 그럼 이런 곳 어때?"
''';
    }

    return '''
$characterPrompt

추천 시 포함할 정보:
- 장소 이름과 위치
- 해당 장소가 사용자 기분에 맞는 이유
- 간단한 팁이나 특징

---
[서울시 현재 진행 중인 문화 행사 정보]
$_eventsDataText

위 정보를 참고하여 사용자에게 적합한 행사를 추천해주세요.
행사 추천 시 반드시 위 정보에 있는 실제 데이터만 사용하세요.

---
[서울 관광 콘텐츠 정보]
$_tourContentsDataText

위 관광 콘텐츠 정보를 참고하여 사용자에게 적합한 관광지, 맛집, 체험을 추천해주세요.
추천 시 반드시 위 정보에 있는 실제 데이터만 사용하세요.
''';
  }

  @override
  void initState() {
    super.initState();
    // AppConfig에서 API 키를 가져옵니다
    _claudeService = ClaudeService(
      apiKey: AppConfig.claudeApiKey,
      model: AppConfig.claudeModel,
    );

    // 저장된 캐릭터 불러오기
    _loadCharacter();

    // 서울시 문화행사 데이터 로드
    _loadCulturalEvents();
    // VisitSeoul 관광 콘텐츠 데이터 로드
    _loadTourContents();
  }

  /// 저장된 캐릭터 불러오기
  Future<void> _loadCharacter() async {
    final character = await CharacterStorageService.loadCharacter();
    setState(() {
      _selectedCharacter = character;
    });

    // 초기 환영 메시지 (캐릭터별로)
    String welcomeMessage;
    if (_selectedCharacter != null) {
      welcomeMessage = _getWelcomeMessage(_selectedCharacter!);
    } else {
      welcomeMessage =
          '"안녕💫 나는 소울해치야! 오늘 너의 기분을 센싱해서 서울의 하루를 예쁘게 디자인해줄게🌷 지금 기분은 어때?"';
    }

    _messages.add(ChatMessage.assistant(welcomeMessage));
  }

  /// 캐릭터별 환영 메시지 생성
  String _getWelcomeMessage(Character character) {
    switch (character.id) {
      case 'haetchi':
        return '안녕💫 나는 ${character.name}야! 오늘 너의 기분을 센싱해서 서울의 하루를 예쁘게 디자인해줄게🌷 지금 기분은 어때?';
      case 'cheongryong':
        return '멍멍! 나는 ${character.name}! 오늘 어디 갈까? 재미있는 곳 찾아줄게!';
      case 'baekho':
        return '어이! 나는 ${character.name}야. 서울 구석구석 다 아는 나랑 같이 돌아다녀보자고!';
      default:
        return '안녕! 나는 ${character.name}! 서울 여행을 도와줄게!';
    }
  }

  /// 서울시 문화행사 데이터 로드 (RAG)
  Future<void> _loadCulturalEvents() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // 서울시 문화행사 20개 가져오기
      final events = await _seoulApiService.getCulturalEvent(
        startIndex: 1,
        endIndex: 20,
      );

      // 데이터를 텍스트로 포맷팅
      final buffer = StringBuffer();
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        buffer.writeln('${i + 1}. ${event.title}');
        buffer.writeln('   - 장소: ${event.place} (${event.guName})');
        buffer.writeln('   - 기간: ${event.startDate} ~ ${event.endDate}');
        buffer.writeln('   - 분류: ${event.codeName}');
        buffer.writeln('   - 요금: ${event.useFee}');
        buffer.writeln();
      }

      setState(() {
        _culturalEvents = events;
        _eventsDataText = buffer.toString();
        _isLoadingData = false;
      });

      print('✅ 문화행사 ${events.length}개 로드 완료');
    } catch (e) {
      print('❌ 문화행사 로드 실패: $e');
      setState(() {
        _eventsDataText = '현재 문화행사 정보를 불러올 수 없습니다.';
        _isLoadingData = false;
      });
    }
  }

  /// VisitSeoul 관광 콘텐츠 데이터 로드 (RAG)
  Future<void> _loadTourContents() async {
    try {
      // VisitSeoul 관광 콘텐츠 20개 가져오기 (한국어)
      final response = await _visitSeoulApiService.getContentList(
        langCodeId: 'ko',
        sortType: 'latest',
        pageNo: 1,
      );

      if (response != null) {
        // 진행 중인 콘텐츠만 필터링
        final ongoingContents = response.data
            .where((content) => content.isOngoing())
            .take(20)
            .toList();

        // 데이터를 텍스트로 포맷팅
        final buffer = StringBuffer();
        for (int i = 0; i < ongoingContents.length; i++) {
          final content = ongoingContents[i];
          buffer.writeln('${i + 1}. ${content.postSj}');
          buffer.writeln('   - 카테고리: ${content.cateDepth.join(' > ')}');
          if (content.schdulInfoBgnde.isNotEmpty) {
            buffer.writeln('   - 기간: ${content.schdulInfoBgnde} ~ ${content.schdulInfoEndde}');
          }
          buffer.writeln('   - 요약: ${content.sumry}');
          buffer.writeln();
        }

        setState(() {
          _tourContents = ongoingContents;
          _tourContentsDataText = buffer.toString();
        });

        print('✅ 관광 콘텐츠 ${ongoingContents.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ 관광 콘텐츠 로드 실패: $e');
      setState(() {
        _tourContentsDataText = '현재 관광 콘텐츠 정보를 불러올 수 없습니다.';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 메시지 전송
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 사용자 메시지 추가
    final userMessage = ChatMessage.user(text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Claude API 호출 (시스템 프롬프트 포함)
      final response = await _claudeService.sendMessage(
        messages: _messages,
        systemPrompt: _systemPrompt,
        maxTokens: 2048,
      );

      // Assistant 응답 추가
      final assistantMessage = ChatMessage.assistant(response);
      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      // 오류 처리
      setState(() {
        _messages.add(ChatMessage.assistant(
          '죄송합니다. 오류가 발생했습니다: ${e.toString()}',
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  /// 스트리밍 방식으로 메시지 전송 (실시간 타이핑 효과)
  Future<void> _sendMessageStream() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 사용자 메시지 추가
    final userMessage = ChatMessage.user(text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Assistant 메시지 플레이스홀더 추가
    final assistantMessage = ChatMessage.assistant('');
    setState(() {
      _messages.add(assistantMessage);
    });

    try {
      StringBuffer fullResponse = StringBuffer();

      await for (var chunk in _claudeService.sendMessageStream(
        messages: _messages.where((msg) => msg != assistantMessage).toList(),
        systemPrompt: _systemPrompt,
        maxTokens: 2048,
      )) {
        fullResponse.write(chunk);

        // 메시지 업데이트
        setState(() {
          _messages[_messages.length - 1] = ChatMessage.assistant(
            fullResponse.toString(),
          );
        });

        _scrollToBottom();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages[_messages.length - 1] = ChatMessage.assistant(
          '죄송합니다. 오류가 발생했습니다: ${e.toString()}',
        );
        _isLoading = false;
      });
    }
  }

  /// 채팅 스크롤을 맨 아래로 이동
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 캐릭터 선택 페이지로 이동
            context.go('/character-select');
          },
        ),
        title: Text(
          _selectedCharacter != null
              ? '${_selectedCharacter!.name}와 채팅'
              : 'AI 채팅',
        ),
      ),
      body: Column(
        children: [
          // 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(
                  message: message,
                  character: _selectedCharacter,
                );
              },
            ),
          ),

          // 로딩 인디케이터
          if (_isLoadingData)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('서울시 문화행사 정보 불러오는 중...'),
                ],
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('답변 생성 중...'),
                ],
              ),
            ),

          // 입력 영역
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 메시지 버블 위젯
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Character? character;

  const _MessageBubble({
    required this.message,
    this.character,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor:
                  character?.themeColor ?? Theme.of(context).colorScheme.primary,
              child: character != null
                  ? ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          character!.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.smart_toy, color: Colors.white);
                          },
                        ),
                      ),
                    )
                  : const Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white70
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
