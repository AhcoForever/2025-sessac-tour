import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/config.dart';
import '../../public_data/models/cultural_event.dart';
import '../../public_data/models/content_list_item.dart';
import '../../public_data/models/park_info.dart';
import '../../public_data/models/cultural_space.dart';
import '../../public_data/services/seoulapi_service.dart';
import '../../public_data/services/visitseoul_api_service.dart';
import '../../map/services/location_service.dart';
import '../models/chat_message.dart';
import '../models/chracter.dart';
import '../models/recommendation.dart';
import '../services/claude_service.dart';
import '../services/character_storage_service.dart';
import '../services/prompt_builder.dart';
import 'widgets/message_bubble.dart';

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
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  bool _isLoadingData = true; // 데이터 로딩 중
  List<CulturalEvent> _culturalEvents = [];
  List<ContentListItem> _tourContents = [];
  List<ParkInfo> _parkInfos = [];
  List<CulturalSpace> _culturalSpaces = [];
  Character? _selectedCharacter; // 선택된 캐릭터
  String? _selectedCategory; // 선택된 카테고리
  Position? _currentPosition; // 현재 위치
  String? _currentLocation; // 현재 위치 설명 (예: "강남구")

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

  // 🎯 시스템 프롬프트 생성 (PromptBuilder 사용)
  String get _systemPrompt {
    return PromptBuilder.buildSystemPrompt(
      character: _selectedCharacter,
      culturalEvents: _culturalEvents,
      tourContents: _tourContents,
      parkInfos: _parkInfos,
      culturalSpaces: _culturalSpaces,
      currentLocation: _currentLocation,
    );
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
    // 서울시 공원 정보 데이터 로드
    _loadParkInfo();
    // 서울시 문화 공간 정보 데이터 로드
    _loadCulturalSpace();
    // 위치 정보 로드
    _loadLocation();
  }

  /// 위치 정보 로드
  Future<void> _loadLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
          // 간단하게 위도/경도를 저장 (추후 Geocoding으로 주소 변환 가능)
          _currentLocation = '위도: ${position.latitude.toStringAsFixed(4)}, 경도: ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      // 위치 정보 로드 실패 시 무시
    }
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
          '안녕. 나는 소울해치야. 오늘 너의 기분을 센싱해서 서울의 하루를 예쁘게 디자인해줄게. 지금 기분은 어때?';
    }

    _messages.add(ChatMessage.assistant(welcomeMessage));
  }

  /// 캐릭터별 환영 메시지 생성
  String _getWelcomeMessage(Character character) {
    switch (character.id) {
      case 'haetchi':
        return '안녕. 나는 ${character.name}야. 오늘 너의 기분을 센싱해서 서울의 하루를 예쁘게 디자인해줄게. 지금 기분은 어때?';
      case 'cheongryong':
        return '안녕! 나는 ${character.name}이용! 오늘 어디 갈까용? 재미있는 곳 찾아줄게용!';
      case 'baekho':
        return '어이! 나는 ${character.name}야. 서울 구석구석 다 아는 나랑 같이 돌아다녀보자고! 어디 가고 싶은 데 있어?';
      default:
        return '안녕! 나는 ${character.name}이야. 서울에서 너가 하루를 알차게 보내도록 도와줄게!';
    }
  }

  /// 서울시 문화행사 데이터 로드 (RAG)
  Future<void> _loadCulturalEvents() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // 서울시 문화행사 100개 가져오기
      final events = await _seoulApiService.getCulturalEvent(
        startIndex: 1,
        endIndex: 100,
      );

      setState(() {
        _culturalEvents = events;
        _isLoadingData = false;
      });

      print('✅ 문화행사 ${events.length}개 로드 완료');
    } catch (e) {
      print('❌ 문화행사 로드 실패: $e');
      setState(() {
        _culturalEvents = [];
        _isLoadingData = false;
      });
    }
  }

  /// VisitSeoul 관광 콘텐츠 데이터 로드 (RAG)
  Future<void> _loadTourContents() async {
    try {
      // VisitSeoul 관광 콘텐츠 100개 가져오기 (한국어)
      final response = await _visitSeoulApiService.getContentList(
        langCodeId: 'ko',
        sortType: 'latest',
        pageNo: 1,
      );

      if (response != null) {
        // 진행 중인 콘텐츠만 필터링
        final ongoingContents = response.data
            .where((content) => content.isOngoing())
            .take(100)
            .toList();

        setState(() {
          _tourContents = ongoingContents;
        });

        print('✅ 관광 콘텐츠 ${ongoingContents.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ 관광 콘텐츠 로드 실패: $e');
      setState(() {
        _tourContents = [];
      });
    }
  }

  /// 서울시 공원 정보 데이터 로드 (RAG)
  Future<void> _loadParkInfo() async {
    try {
      // 서울시 공원 정보 50개 가져오기
      final response = await _seoulApiService.getParkInfo(
        startIndex: 1,
        endIndex: 50,
      );

      if (response != null && response.result.isSuccess) {
        setState(() {
          _parkInfos = response.row;
        });

        print('✅ 공원 정보 ${response.row.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ 공원 정보 로드 실패: $e');
      setState(() {
        _parkInfos = [];
      });
    }
  }

  /// 서울시 문화 공간 정보 데이터 로드 (RAG)
  Future<void> _loadCulturalSpace() async {
    try {
      // 서울시 문화 공간 정보 50개 가져오기
      final response = await _seoulApiService.getCulturalSpace(
        startIndex: 1,
        endIndex: 50,
      );

      if (response != null && response.result.isSuccess) {
        setState(() {
          _culturalSpaces = response.row;
        });

        print('✅ 문화 공간 정보 ${response.row.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ 문화 공간 정보 로드 실패: $e');
      setState(() {
        _culturalSpaces = [];
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

      // 응답 파싱 (텍스트 + 추천 데이터)
      final (textPart, recommendations) = _parseResponse(response);

      // Assistant 응답 추가
      final assistantMessage = ChatMessage.assistant(
        textPart,
        recommendations: recommendations,
      );
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

  /// Claude 응답에서 추천 데이터 파싱
  ///
  /// 응답 형식: 텍스트 + [RECOMMENDATIONS]JSON[/RECOMMENDATIONS]
  /// 반환: (텍스트 부분, 추천 리스트)
  (String, List<Recommendation>?) _parseResponse(String response) {
    // [RECOMMENDATIONS]...[/RECOMMENDATIONS] 태그 찾기
    final startTag = '[RECOMMENDATIONS]';
    final endTag = '[/RECOMMENDATIONS]';

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

  /// 카테고리 버튼 생성
  Widget _buildCategoryButton(String category, String emoji) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          // 같은 카테고리를 누르면 토글 (닫기)
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
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
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
      onTap: () {
        // 예시 질문 클릭 시 자동으로 전송
        _sendExampleQuestion(question);
      },
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

  /// 예시 질문 전송
  Future<void> _sendExampleQuestion(String question) async {
    if (_isLoading) return;

    // 예시 질문을 사용자 메시지로 추가
    final userMessage = ChatMessage.user(question);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _selectedCategory = null; // 예시 질문 전송 후 카테고리 선택 해제
    });

    _scrollToBottom();

    try {
      // Claude API 호출
      final response = await _claudeService.sendMessage(
        messages: _messages,
        systemPrompt: _systemPrompt,
        maxTokens: 2048,
      );

      // 응답 파싱 (텍스트 + 추천 데이터)
      final (textPart, recommendations) = _parseResponse(response);

      // Assistant 응답 추가
      final assistantMessage = ChatMessage.assistant(
        textPart,
        recommendations: recommendations,
      );
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
              ? '${_selectedCharacter!.name}'
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
                return MessageBubble(
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
                        .map((question) => _buildExampleQuestion(question))
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
