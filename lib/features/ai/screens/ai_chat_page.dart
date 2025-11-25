import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config.dart';
import '../managers/data_fetch_manager.dart';
import '../managers/chat_message_handler.dart';
import '../managers/chat_profile_manager.dart';
import '../managers/character_manager.dart';
import '../services/claude_service.dart';
import 'widgets/message_bubble.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Managers
  late final DataFetchManager _dataFetchManager;
  late final ChatMessageHandler _messageHandler;
  final ChatProfileManager _profileManager = ChatProfileManager();
  final CharacterManager _characterManager = CharacterManager();

  String? _selectedCategory;

  // 카테고리별 예시 질문
  final Map<String, List<String>> _exampleQuestions = {
    '힐링': [
      '오늘 날씨 좋은데 뭐 할까요',
      '조용한 곳에서 쉬고 싶어요',
      '산책하기 좋은 곳 추천해주세요',
    ],
    '무기력': [
      '집에만 있었는데 뭐 하면 좋을까요',
      '기분 전환할 수 있는 곳 알려주세요',
      '가벼운 활동 추천해주세요',
    ],
    '외로움': [
      '사람 많은 곳 추천해주세요',
      '혼자 가기 좋은 카페 알려주세요',
      '새로운 사람들을 만날 수 있는 활동 추천해주세요',
    ],
    '날씨': [
      '오늘 날씨 좋은데 뭐 할까요',
      '실내에서 할 수 있는 활동 추천해줘',
      '비 오는 날 갈 만한 곳 있을까요',
    ],
    '예산': [
      '무료로 즐길 수 있는 곳 알려주세요',
      '저렴하게 즐길 수 있는 활동 추천해주세요',
      '가성비 좋은 맛집 알려주세요',
    ],
    '근처': [
      '지금 있는 곳 근처에서 뭐 할까요',
      '가까운 곳 추천해주세요',
      '도보로 갈 수 있는 곳 알려주세요',
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeManagers();
    _loadInitialData();
  }

  /// 매니저 초기화
  void _initializeManagers() {
    _dataFetchManager = DataFetchManager();

    final claudeService = ClaudeService(
      apiKey: AppConfig.claudeApiKey,
      model: AppConfig.claudeModel,
    );
    _messageHandler = ChatMessageHandler(claudeService: claudeService);
  }

  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    try {
      // 캐릭터 로드
      await _characterManager.loadCharacter();

      // 환영 메시지 추가
      final welcomeMessage = _characterManager.getWelcomeMessage();
      _messageHandler.addWelcomeMessage(welcomeMessage);

      // 데이터 로드
      await _dataFetchManager.loadAllData();

      if (mounted) setState(() {});
    } catch (e) {
      print('❌ 초기 데이터 로드 실패: $e');

      // 사용자에게 에러 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터를 불러오는데 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: '재시도',
              textColor: Colors.white,
              onPressed: () => _loadInitialData(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        // 기본 환영 메시지라도 추가
        if (_messageHandler.messages.isEmpty) {
          _messageHandler.addWelcomeMessage('안녕하세요! 데이터 로드 중 문제가 발생했지만 대화는 가능합니다.');
        }

        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 메시지 전송
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _messageHandler.isLoading) return;

    final systemPrompt = _dataFetchManager.buildSystemPrompt(
      _characterManager.selectedCharacter,
    );

    setState(() {
      _selectedCategory = null;
    });

    _scrollToBottom();

    await for (final event in _messageHandler.sendMessage(
      userMessage: text,
      systemPrompt: systemPrompt,
    )) {
      if (event is MessageAdded || event is TextUpdate) {
        setState(() {});
        _scrollToBottom();
      } else if (event is Completed) {
        // 채팅 프로필 업데이트
        await _profileManager.updateProfile(
          characterId: _characterManager.selectedCharacter?.id,
          recommendations: event.recommendations,
        );
        setState(() {});
        _scrollToBottom();
      } else if (event is ErrorOccurred) {
        setState(() {});
        _scrollToBottom();
      }
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

  /// 카테고리 버튼 생성
  Widget _buildCategoryButton(String category, String emoji) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              category,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 예시 질문 버튼 생성
  Widget _buildExampleQuestion(String question) {
    return GestureDetector(
      onTap: () => _sendMessage(question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          question,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final character = _characterManager.selectedCharacter;
    final isLoadingData = _dataFetchManager.isLoadingData;
    final isLoading = _messageHandler.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/character-select'),
        ),
        title: Text(character != null ? character.name : 'AI 채팅'),
      ),
      body: Column(
        children: [
          // 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messageHandler.messages.length,
              itemBuilder: (context, index) {
                final message = _messageHandler.messages[index];
                return MessageBubble(
                  message: message,
                  character: character,
                );
              },
            ),
          ),

          // 로딩 인디케이터
          if (isLoadingData)
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
          if (isLoading)
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

          // 감정 태그 버튼
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryButton('힐링', '🌿'),
                  const SizedBox(width: 8),
                  _buildCategoryButton('무기력', '😔'),
                  const SizedBox(width: 8),
                  _buildCategoryButton('외로움', '💙'),
                  const SizedBox(width: 8),
                  _buildCategoryButton('날씨', '☀️'),
                  const SizedBox(width: 8),
                  _buildCategoryButton('예산', '💰'),
                  const SizedBox(width: 8),
                  _buildCategoryButton('근처', '📍'),
                ],
              ),
            ),
          ),

          // 예시 질문 표시
          if (_selectedCategory != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '예시 질문:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _exampleQuestions[_selectedCategory]!
                        .map(_buildExampleQuestion)
                        .toList(),
                  ),
                  const SizedBox(height: 8),
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
                      onSubmitted: (_) {
                        final text = _messageController.text;
                        _messageController.clear();
                        _sendMessage(text);
                      },
                      enabled: !isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            final text = _messageController.text;
                            _messageController.clear();
                            _sendMessage(text);
                          },
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
