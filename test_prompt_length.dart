import 'lib/features/ai/services/prompt_builder.dart';
import 'lib/features/ai/data/chracter_data.dart';

void main() {
  // 소울해치로 프롬프트 생성
  final haetchi = CharacterData.characters.firstWhere((c) => c.id == 'haetchi');

  final prompt = PromptBuilder.buildSystemPrompt(
    character: haetchi,
    culturalEvents: [],
    tourContents: [],
    parkInfos: [],
    culturalSpaces: [],
  );

  print('============================================');
  print('프롬프트 분석 결과');
  print('============================================');
  print('총 글자 수: ${prompt.length} characters');
  print('총 줄 수: ${prompt.split('\n').length} lines');
  print('버전: ${PromptBuilder.version}');
  print('마지막 업데이트: ${PromptBuilder.lastUpdated}');
  print('============================================\n');

  // 영어 지시사항 확인
  final englishInstructions = [
    '[Common Role for All Characters]',
    '[Persona: Soul Haetchi]',
    '[Travel Guide Role]',
    '[Decision-Making Rules]',
    '[Emotion Empathy Principles]',
    '[Output Format]',
    '[Data Usage Rules]',
  ];

  print('✅ 영어 지시사항 확인:');
  for (final instruction in englishInstructions) {
    final exists = prompt.contains(instruction);
    print('  ${exists ? '✓' : '✗'} $instruction');
  }
  print('');

  // 한글 예시 확인
  final koreanExamples = [
    '토닥토닥',
    '다 잘 될 거야',
    '~용!',
    '돌격!',
  ];

  print('✅ 한글 예시 확인:');
  for (final example in koreanExamples) {
    final exists = prompt.contains(example);
    print('  ${exists ? '✓' : '✗'} "$example"');
  }
  print('');

  // "Always respond in Korean" 확인
  print('✅ 한국어 응답 지시:');
  print('  ${prompt.contains('Always respond in Korean') ? '✓' : '✗'} Always respond in Korean');
  print('');

  // 프롬프트 샘플 출력 (처음 500자)
  print('============================================');
  print('프롬프트 샘플 (처음 500자):');
  print('============================================');
  print(prompt.substring(0, prompt.length > 500 ? 500 : prompt.length));
  print('...\n');
}
