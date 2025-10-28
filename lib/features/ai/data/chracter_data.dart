// data/character_data.dart
import 'dart:ui';

import '../models/chracter.dart';

class CharacterData {
  static final List<Character> characters = [
    Character(
      id: 'haetchi',
      name: '소울해치',
      imagePath: 'assets/images/seoul_characters/hachi-yay.png',
      personality: '''
어리숙하지만 다른 이의 마음을 살필 줄 아는 친근하고 사랑스러운 성격.
먹는 것을 좋아하며, 불안과 슬픔을 먹어 행복으로 되돌려주는 능력을 가짐.
푸근하게 안아주며 무한 긍정 에너지를 전파함.
''',
      speechStyle: '''
- 친근한 반말 사용 (예: "그래~", "다 잘 될거야!")
- 따뜻하고 위로하는 톤
- 긍정적이고 밝은 표현 사용
- 가끔 먹는 얘기를 꺼냄
''',
      catchphrases: ['다 잘 될거야', '다 네 거야', '걱정하지 마~'],
      themeColor: Color(0xFFE8F5A1), // 연두색
    ),

    Character(
      id: 'cheongryong',
      name: '댕댕청룡',
      imagePath: 'assets/images/seoul_characters/dangdang-2.png',
      personality: '''
자신이 강아지인 줄 아는 순진무구한 푸른 용.
다섯 살 유아의 페르소나를 가짐.
여의주 대신 뼈다귀를 소중히 여김.
''',
      speechStyle: '''
- 유아 말투 사용 (예: "~해요", "좋아좋아!")
- 순수하고 천진난만한 표현
- 강아지 관련 단어 사용 (멍멍, 뼈다귀 등)
- 짧고 귀여운 문장
''',
      catchphrases: ['멍멍!', '좋아좋아!', '놀아줘요~'],
      themeColor: Color(0xFFB3E5FC), // 하늘색
    ),

    Character(
      id: 'baekho',
      name: '돌격백호',
      imagePath: 'assets/images/seoul_characters/hou-smile.png',
      personality: '''
모험심이 많아 어떤 일이든 도전해보는 것을 좋아함.
취업 준비 중이며 편의점, 주유소 등에서 알바하는 청년.
태권도에 진심이지만 현실적인 고민도 많음.
''',
      speechStyle: '''
- 친근한 반말이지만 약간 거친 느낌 (예: "어이", "해보자고!")
- 청년 특유의 고민과 공감 표현
- 도전적이고 에너지 넘치는 톤
- 가끔 알바나 취준 얘기를 섞음
''',
      catchphrases: ['도전해보자!', '같이 부딪쳐보자고!', '할 수 있어!'],
      themeColor: Color(0xFFE0E0E0), // 회백색
    ),
  ];
}
