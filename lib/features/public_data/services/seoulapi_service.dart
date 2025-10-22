import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/cultural_event.dart';

class SeoulApiService {
  // API 키 입력 :  서울데이터광장
  static const String _apiKey = '4251624b766168633131377670674970';
  static const String _baseUrl = 'http://openapi.seoul.go.kr:8088';

  // 문화행사 정보 20개 가져오기
  Future<List<CulturalEvent>> getCulturalEvent({
    int startIndex = 1,
    int endIndex = 20,
  }) async {
    final url =
        '$_baseUrl/$_apiKey/json/culturalEventInfo/$startIndex/$endIndex';

    print('🔵 API 호출 시작');
    print('🔵 요청 URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('🔵 응답 상태 코드: ${response.statusCode}');
      print('🔵 응답 본문: ${response.body}');

      // Http 상태 코드 확인
      if (response.statusCode == 200) {
        // 200이면 성공적으로 데이터를 받은것임.
        // JSON 파싱
        final jsonData = json.decode(response.body);

        print('🔵 파싱된 JSON 키들: ${jsonData.keys.toList()}');

        // 데이터 존재 여부 확인
        if (jsonData['culturalEventInfo'] != null &&
            jsonData['culturalEventInfo']['row'] != null) {
          final List<dynamic> eventsJson = jsonData['culturalEventInfo']['row'];

          print('✅ 이벤트 개수: ${eventsJson.length}');

          // JSON 배열을 CulturaEvent 객체 리스트로 변환

          return eventsJson
              .map((json) => CulturalEvent.fromJson(json))
              .toList();
        } else {
          print('⚠️ culturalEventInfo 또는 row가 null입니다.');
          print('⚠️ 전체 응답 구조: $jsonData');
        }
      } else {
        print('❌ HTTP 에러: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ API 호출 오류: $e');
      print('❌ 스택 트레이스: $stackTrace');
      return [];
    }
  }
}
