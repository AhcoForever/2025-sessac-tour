import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/cultural_event.dart';
import '../models/night_spot.dart';
import '../models/park_info.dart';
import '../models/cultural_space.dart';

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

  // 서울시 야경명소 정보 가져오기
  Future<NightSpotResponse?> getNightSpots({
    int startIndex = 1,
    int endIndex = 100,
  }) async {
    final url = '$_baseUrl/$_apiKey/json/viewNightSpot/$startIndex/$endIndex/';

    print('🌙 야경명소 API 호출 시작');
    print('🔗 요청 URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // 데이터 존재 여부 확인
        if (jsonData['viewNightSpot'] != null) {
          final nightSpotResponse = NightSpotResponse.fromJson(jsonData);

          if (nightSpotResponse.result.isSuccess) {
            print('✅ 야경명소 ${nightSpotResponse.row.length}개 로드 성공');
            return nightSpotResponse;
          } else {
            print('⚠️ API 결과 코드: ${nightSpotResponse.result.code}');
            print('⚠️ 메시지: ${nightSpotResponse.result.message}');
            return null;
          }
        } else {
          print('⚠️ viewNightSpot 데이터가 null입니다.');
          return null;
        }
      } else {
        print('❌ HTTP 에러: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ 야경명소 API 호출 오류: $e');
      print('❌ 스택 트레이스: $stackTrace');
      return null;
    }
  }

  // 서울시 주요 공원현황 정보 가져오기
  Future<ParkInfoResponse?> getParkInfo({
    int startIndex = 1,
    int endIndex = 50,
  }) async {
    final url =
        '$_baseUrl/$_apiKey/json/SearchParkInfoService/$startIndex/$endIndex/';

    print('🌳 공원 정보 API 호출 시작');
    print('🔗 요청 URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // 데이터 존재 여부 확인
        if (jsonData['SearchParkInfoService'] != null) {
          final parkInfoResponse = ParkInfoResponse.fromJson(jsonData);

          if (parkInfoResponse.result.isSuccess) {
            print('✅ 공원 정보 ${parkInfoResponse.row.length}개 로드 성공');
            return parkInfoResponse;
          } else {
            print('⚠️ API 결과 코드: ${parkInfoResponse.result.code}');
            print('⚠️ 메시지: ${parkInfoResponse.result.message}');
            return null;
          }
        } else {
          print('⚠️ SearchParkInfoService 데이터가 null입니다.');
          return null;
        }
      } else {
        print('❌ HTTP 에러: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ 공원 정보 API 호출 오류: $e');
      print('❌ 스택 트레이스: $stackTrace');
      return null;
    }
  }

  // 서울시 문화 공간 정보 가져오기
  Future<CulturalSpaceResponse?> getCulturalSpace({
    int startIndex = 1,
    int endIndex = 50,
  }) async {
    final url =
        '$_baseUrl/$_apiKey/json/culturalSpaceInfo/$startIndex/$endIndex/';

    print('🎭 문화 공간 정보 API 호출 시작');
    print('🔗 요청 URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // 데이터 존재 여부 확인
        if (jsonData['culturalSpaceInfo'] != null) {
          final culturalSpaceResponse =
              CulturalSpaceResponse.fromJson(jsonData);

          if (culturalSpaceResponse.result.isSuccess) {
            print('✅ 문화 공간 정보 ${culturalSpaceResponse.row.length}개 로드 성공');
            return culturalSpaceResponse;
          } else {
            print('⚠️ API 결과 코드: ${culturalSpaceResponse.result.code}');
            print('⚠️ 메시지: ${culturalSpaceResponse.result.message}');
            return null;
          }
        } else {
          print('⚠️ culturalSpaceInfo 데이터가 null입니다.');
          return null;
        }
      } else {
        print('❌ HTTP 에러: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ 문화 공간 정보 API 호출 오류: $e');
      print('❌ 스택 트레이스: $stackTrace');
      return null;
    }
  }
}
