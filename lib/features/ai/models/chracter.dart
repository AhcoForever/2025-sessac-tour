import 'dart:ui';

class Character {
  final String id;
  final String name;
  final String imagePath;
  final String personality; // 성격 설명
  final String speechStyle; // 말투 특성
  final List<String> catchphrases; // 캐치프레이즈
  final Color themeColor; // 테마 컬러

  Character({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.personality,
    required this.speechStyle,
    required this.catchphrases,
    required this.themeColor,
  });

  // AI에게 전달할 시스템 프롬프트 생성
  String getSystemPrompt() {
    String prompt =
        '''
당신은 "$name"입니다.

성격과 특징:
$personality

말투 특성:
$speechStyle

자주 사용하는 표현:
${catchphrases.join(', ')}

위 캐릭터의 성격과 말투를 완벽하게 재현하여 대화해주세요.
''';
    return prompt;
  }
}
