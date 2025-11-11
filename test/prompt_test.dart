import 'package:flutter_test/flutter_test.dart';
import 'package:sessac_tour/features/ai/services/prompt_builder.dart';
import 'package:sessac_tour/features/ai/models/chracter.dart';
import 'package:sessac_tour/features/ai/data/chracter_data.dart';

void main() {
  group('Prompt Builder Tests', () {
    test('Should generate English prompt with Korean examples', () {
      // Given: 소울해치 캐릭터 선택
      final haetchi = CharacterData.characters
          .firstWhere((c) => c.id == 'haetchi');

      // When: 프롬프트 생성
      final prompt = PromptBuilder.buildSystemPrompt(
        character: haetchi,
        culturalEvents: [],
        tourContents: [],
        parkInfos: [],
        culturalSpaces: [],
      );

      // Then: 영어 지시사항과 한글 예시가 모두 포함되어야 함
      print('\n========== GENERATED PROMPT ==========');
      print(prompt);
      print('\n======================================\n');

      // 영어 지시사항 확인
      expect(prompt.contains('[Common Role for All Characters]'), true);
      expect(prompt.contains('[Persona: Soul Haetchi]'), true);
      expect(prompt.contains('[Travel Guide Role]'), true);
      expect(prompt.contains('[Decision-Making Rules]'), true);
      expect(prompt.contains('[Output Format]'), true);

      // 한글 예시 확인
      expect(prompt.contains('토닥토닥'), true);
      expect(prompt.contains('다 잘 될 거야'), true);

      // "Always respond in Korean" 확인
      expect(prompt.contains('Always respond in Korean'), true);
    });

    test('Should include all three character prompts', () {
      final characters = CharacterData.characters;

      for (final character in characters) {
        final prompt = PromptBuilder.buildSystemPrompt(
          character: character,
          culturalEvents: [],
          tourContents: [],
          parkInfos: [],
          culturalSpaces: [],
        );

        print('\n========== ${character.name} PROMPT ==========');

        // 캐릭터별 고유 표현 확인
        if (character.id == 'haetchi') {
          expect(prompt.contains('Soul Haetchi'), true);
          expect(prompt.contains('토닥토닥'), true);
        } else if (character.id == 'cheongryong') {
          expect(prompt.contains('Dangdang Cheongryong'), true);
          expect(prompt.contains('~용!'), true);
        } else if (character.id == 'baekho') {
          expect(prompt.contains('Dolgyeok Baekho'), true);
          expect(prompt.contains('돌격!'), true);
        }
      }
    });

    test('Should format data sections in English', () {
      final prompt = PromptBuilder.buildSystemPrompt(
        character: null,
        culturalEvents: [],
        tourContents: [],
        parkInfos: [],
        culturalSpaces: [],
      );

      // 데이터 섹션 헤더가 영어인지 확인
      expect(prompt.contains('[Seoul Cultural Events Currently in Progress]'), true);
      expect(prompt.contains('[Seoul Tourism Content Information]'), true);
      expect(prompt.contains('[Seoul Major Parks Information]'), true);
      expect(prompt.contains('[Seoul Cultural Spaces Information]'), true);
    });

    test('Should verify prompt version updated to 2.0.0', () {
      expect(PromptBuilder.version, '2.0.0');
      expect(PromptBuilder.lastUpdated, '2025-11-11');
    });
  });
}
