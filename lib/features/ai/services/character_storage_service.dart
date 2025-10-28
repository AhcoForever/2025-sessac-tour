import 'package:shared_preferences/shared_preferences.dart';
import '../models/chracter.dart';
import '../data/chracter_data.dart';

class CharacterStorageService {
  static const String _characterIdKey = 'selected_character_id';

  /// 선택한 캐릭터 저장
  static Future<void> saveCharacter(Character character) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_characterIdKey, character.id);
  }

  /// 저장된 캐릭터 불러오기
  static Future<Character?> loadCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final characterId = prefs.getString(_characterIdKey);

    if (characterId == null) {
      return null;
    }

    // characterId로 캐릭터 찾기
    try {
      return CharacterData.characters.firstWhere(
        (char) => char.id == characterId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 저장된 캐릭터 삭제
  static Future<void> clearCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_characterIdKey);
  }
}
