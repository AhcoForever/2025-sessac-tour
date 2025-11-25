import '../models/chracter.dart';
import '../services/character_storage_service.dart';

/// 캐릭터 관리를 담당하는 클래스
class CharacterManager {
  Character? _selectedCharacter;

  // Getter
  Character? get selectedCharacter => _selectedCharacter;

  /// 저장된 캐릭터 불러오기
  Future<Character?> loadCharacter() async {
    _selectedCharacter = await CharacterStorageService.loadCharacter();
    return _selectedCharacter;
  }

  /// 캐릭터별 환영 메시지 생성
  String getWelcomeMessage() {
    if (_selectedCharacter == null) {
      return '안녕. 나는 소울해치야. 오늘 너의 기분을 센싱해서 서울의 하루를 예쁘게 디자인해줄게. 지금 기분은 어때?';
    }

    final character = _selectedCharacter!;

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
}
