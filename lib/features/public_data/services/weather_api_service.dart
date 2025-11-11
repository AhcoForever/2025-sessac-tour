import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sessactour/core/config.dart';
import 'package:sessactour/features/public_data/models/weather_info.dart';

/// 기상청 중기예보 API 서비스
///
/// API 문서: https://www.data.go.kr/tcs/dss/selectApiDataDetailView.do?publicDataPk=15059468
class WeatherApiService {
  static const String _baseUrl = 'https://apis.data.go.kr/1360000/MidFcstInfoService';

  // 서울, 인천, 경기도 지역 코드
  static const String _seoulRegionCode = '11B00000';
  static const String _seoulTempRegionCode = '11B10101'; // 서울 기온 코드

  /// 중기예보 조회 (육상 + 기온 통합)
  ///
  /// 3~10일 예보를 반환합니다.
  Future<WeatherForecast?> getMidForecast() async {
    try {
      // 발표 시각 계산 (중기예보는 하루 2회: 06:00, 18:00)
      final tmFc = _getBaseDateTime();

      // 1. 중기육상예보 조회
      final landForecast = await _getMidLandFcst(tmFc);
      if (landForecast == null) {
        print('중기육상예보 조회 실패');
        return null;
      }

      // 2. 중기기온예보 조회
      final tempForecast = await _getMidTa(tmFc);
      if (tempForecast == null) {
        print('중기기온예보 조회 실패');
        return null;
      }

      // 3. 데이터 통합
      return WeatherForecast.fromMidForecast(landForecast, tempForecast);
    } catch (e) {
      print('중기예보 조회 중 오류: $e');
      return null;
    }
  }

  /// 중기육상예보 조회 (강수확률, 하늘상태)
  Future<Map<String, dynamic>?> _getMidLandFcst(String tmFc) async {
    try {
      final uri = Uri.parse('$_baseUrl/getMidLandFcst').replace(
        queryParameters: {
          'serviceKey': AppConfig.weatherApiKey,
          'pageNo': '1',
          'numOfRows': '10',
          'dataType': 'JSON',
          'regId': _seoulRegionCode,
          'tmFc': tmFc,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // API 응답 체크
        final header = data['response']?['header'];
        if (header?['resultCode'] != '00') {
          print('기상청 육상예보 API 오류: ${header?['resultMsg']}');
          return null;
        }

        final items = data['response']?['body']?['items']?['item'];
        if (items == null || (items is List && items.isEmpty)) {
          print('육상예보 데이터 없음');
          return null;
        }

        // items가 리스트면 첫 번째 요소, 아니면 그대로
        return items is List ? items[0] : items;
      } else {
        print('기상청 육상예보 API 요청 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('중기육상예보 조회 중 오류: $e');
      return null;
    }
  }

  /// 중기기온예보 조회 (최저/최고기온)
  Future<Map<String, dynamic>?> _getMidTa(String tmFc) async {
    try {
      final uri = Uri.parse('$_baseUrl/getMidTa').replace(
        queryParameters: {
          'serviceKey': AppConfig.weatherApiKey,
          'pageNo': '1',
          'numOfRows': '10',
          'dataType': 'JSON',
          'regId': _seoulTempRegionCode,
          'tmFc': tmFc,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // API 응답 체크
        final header = data['response']?['header'];
        if (header?['resultCode'] != '00') {
          print('기상청 기온예보 API 오류: ${header?['resultMsg']}');
          return null;
        }

        final items = data['response']?['body']?['items']?['item'];
        if (items == null || (items is List && items.isEmpty)) {
          print('기온예보 데이터 없음');
          return null;
        }

        // items가 리스트면 첫 번째 요소, 아니면 그대로
        return items is List ? items[0] : items;
      } else {
        print('기상청 기온예보 API 요청 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('중기기온예보 조회 중 오류: $e');
      return null;
    }
  }

  /// 발표 시각 계산
  ///
  /// 중기예보는 하루 2회 발표 (06:00, 18:00)
  /// 형식: YYYYMMDD0600 또는 YYYYMMDD1800
  String _getBaseDateTime() {
    final now = DateTime.now();
    final hour = now.hour;

    // 06시 이전이면 전날 18시, 18시 이전이면 오늘 06시, 그 이후면 오늘 18시
    DateTime baseDateTime;
    String baseTime;

    if (hour < 6) {
      // 전날 18시
      baseDateTime = now.subtract(const Duration(days: 1));
      baseTime = '1800';
    } else if (hour < 18) {
      // 오늘 06시
      baseDateTime = now;
      baseTime = '0600';
    } else {
      // 오늘 18시
      baseDateTime = now;
      baseTime = '1800';
    }

    final date = _formatDate(baseDateTime);
    return '$date$baseTime';
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// 간단한 날씨 요약 가져오기 (AI 프롬프트용)
  Future<String> getWeatherSummary() async {
    final forecast = await getMidForecast();
    if (forecast == null) {
      return '날씨 정보를 가져올 수 없습니다.';
    }

    return forecast.toSummaryString();
  }
}
