import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sessactour/features/ai/screens/widgets/page_indicator.dart';
import '../data/chracter_data.dart';
import '../models/chracter.dart';
import '../services/character_storage_service.dart';

class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({super.key});

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmSelection() async {
    final selectedCharacter = CharacterData.characters[_currentIndex];

    // 선택한 캐릭터 저장
    await CharacterStorageService.saveCharacter(selectedCharacter);

    // 메인 화면으로 이동 (또는 AI 채팅 페이지로)
    if (mounted) {
      context.go('/ai-chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCharacter = CharacterData.characters[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('가이드 선택'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 설명
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Text(
                    '당신의 가이드를 선택하세요',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '각 가이드는 고유한 성격과 말투를 가지고 있어요 \n 좌우로 스와프하여 캐릭터를 둘러보세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // 페이지 인디케이터
            const SizedBox(height: 16),
            PageIndicator(
              currentIndex: _currentIndex,
              itemCount: CharacterData.characters.length,
              activeColor: currentCharacter.themeColor,
            ),

            const SizedBox(height: 32),

            // 캐릭터 PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: CharacterData.characters.length,
                itemBuilder: (context, index) {
                  final character = CharacterData.characters[index];
                  return _CharacterPage(character: character);
                },
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _confirmSelection,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: currentCharacter.themeColor,
                ),
                child: Text(
                  '${currentCharacter.name} 선택하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterPage extends StatelessWidget {
  final Character character;

  const _CharacterPage({required this.character});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 원형 캐릭터 이미지
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: character.themeColor.withValues(alpha: 0.3),
              border: Border.all(color: character.themeColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: character.themeColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  character.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 100,
                      color: character.themeColor,
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 캐릭터 이름
          Text(
            character.name,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),


          // 성격 설명
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              character.personality.trim(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 4),

          // 캐치프레이즈
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: character.catchphrases.map((phrase) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: character.themeColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  phrase,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

