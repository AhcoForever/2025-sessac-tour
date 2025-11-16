import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import '../models/route_info.dart';

/// Google Directions API 서비스
/// 도보 경로 탐색을 제공합니다
class GoogleRoutesService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  // Google Maps API 키 (Android/iOS에 이미 설정된 키 사용)
  static const String _apiKey = 'AIzaSyAI-rnA5WFt8fYbuZK9GX6KjBKUeFCSoVE';

  /// 도보 경로 조회
  ///
  /// [start] 출발지 (위도, 경도)
  /// [goal] 목적지 (위도, 경도)
  /// [mode] 이동 수단 (walking, driving, bicycling, transit)
  Future<RouteInfo?> getWalkingRoute({
    required LatLng start,
    required LatLng goal,
    String mode = 'walking',
  }) async {
    try {
      // 좌표 유효성 검증
      if (!_isValidCoordinate(start) || !_isValidCoordinate(goal)) {
        debugPrint('❌ 유효하지 않은 좌표');
        debugPrint('   출발: ${start.latitude}, ${start.longitude}');
        debugPrint('   도착: ${goal.latitude}, ${goal.longitude}');
        return null;
      }

      // 쿼리 파라미터 구성
      final queryParams = {
        'origin': '${start.latitude},${start.longitude}',
        'destination': '${goal.latitude},${goal.longitude}',
        'mode': mode,
        'key': _apiKey,
        'language': 'ko',
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      debugPrint('🚀 Google Directions API 요청');
      debugPrint('   출발: ${start.latitude}, ${start.longitude}');
      debugPrint('   도착: ${goal.latitude}, ${goal.longitude}');
      debugPrint('   이동 수단: $mode');
      debugPrint('   요청 URL: $uri');

      final response = await http.get(uri);

      debugPrint('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          debugPrint('✅ 경로 조회 성공');
          return _parseDirectionsResponse(data);
        } else {
          debugPrint('❌ 경로 조회 실패: ${data['status']}');
          if (data['error_message'] != null) {
            debugPrint('   에러 메시지: ${data['error_message']}');
          }
          // 전체 응답 출력 (디버깅용)
          debugPrint('📄 전체 응답: ${response.body}');

          // ZERO_RESULTS 상세 안내
          if (data['status'] == 'ZERO_RESULTS') {
            debugPrint('💡 ZERO_RESULTS 해결 방법:');
            debugPrint('   1. 좌표가 올바른지 확인 (위도: -90~90, 경도: -180~180)');
            debugPrint('   2. 출발지와 목적지가 너무 멀지 않은지 확인');
            debugPrint('   3. 다른 이동 수단(driving)으로 시도해보기');
            debugPrint('   4. 좌표가 실제 도로망에 연결되어 있는지 확인');
          }
          return null;
        }
      } else {
        debugPrint('❌ 경로 조회 실패: ${response.statusCode}');
        debugPrint('📄 응답 본문: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 경로 조회 에러: $e');
      return null;
    }
  }

  /// Google Directions API 응답 파싱
  RouteInfo _parseDirectionsResponse(Map<String, dynamic> data) {
    final route = data['routes'][0];
    final leg = route['legs'][0];

    // 경로 좌표 추출
    final List<LatLng> path = [];
    final steps = leg['steps'] as List;

    for (var step in steps) {
      // 각 step의 polyline을 디코딩
      final polylinePoints = _decodePolyline(step['polyline']['points']);
      path.addAll(polylinePoints);
    }

    // 거리와 시간 추출
    final distance = leg['distance']['value'] as int; // 미터 단위
    final duration = leg['duration']['value'] as int; // 초 단위

    debugPrint('📏 거리: ${(distance / 1000).toStringAsFixed(1)}km');
    debugPrint('⏱️ 소요 시간: ${(duration / 60).toStringAsFixed(0)}분');
    debugPrint('📍 경로 포인트 수: ${path.length}');

    // 경로 요약 생성
    final distanceKm = (distance / 1000).toStringAsFixed(1);
    final durationMin = (duration / 60).round();
    final summary = '도보 경로 (${distanceKm}km, 약 $durationMin분)';

    return RouteInfo(
      path: path,
      distance: distance,
      duration: duration * 1000, // 밀리초로 변환
      summary: summary,
    );
  }

  /// Encoded Polyline을 LatLng 리스트로 디코딩
  /// Google의 polyline encoding 알고리즘 구현
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// 거리 계산 (간단한 직선거리)
  /// 실제 경로가 아닌 예상 거리를 계산할 때 사용
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)

    final lat1 = start.latitude * (pi / 180);
    final lat2 = end.latitude * (pi / 180);
    final deltaLat = (end.latitude - start.latitude) * (pi / 180);
    final deltaLon = (end.longitude - start.longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// 좌표 유효성 검증
  bool _isValidCoordinate(LatLng coord) {
    // 위도: -90 ~ 90
    // 경도: -180 ~ 180
    if (coord.latitude < -90 || coord.latitude > 90) {
      debugPrint('⚠️ 유효하지 않은 위도: ${coord.latitude}');
      return false;
    }
    if (coord.longitude < -180 || coord.longitude > 180) {
      debugPrint('⚠️ 유효하지 않은 경도: ${coord.longitude}');
      return false;
    }
    // 0,0 좌표는 실제 데이터가 아닐 가능성이 높음
    if (coord.latitude == 0 && coord.longitude == 0) {
      debugPrint('⚠️ 좌표가 0,0 입니다 (데이터 없음)');
      return false;
    }
    return true;
  }

  /// 테스트용: 알려진 좌표로 API 동작 확인
  Future<void> testWithKnownLocations() async {
    debugPrint('🧪 알려진 좌표로 테스트 시작');

    // 서울시청 -> 경복궁 (약 1.5km)
    final seoulCityHall = LatLng(37.5663, 126.9779);
    final gyeongbokgung = LatLng(37.5796, 126.9770);

    debugPrint('테스트: 서울시청 -> 경복궁');
    final result = await getWalkingRoute(
      start: seoulCityHall,
      goal: gyeongbokgung,
      mode: 'walking',
    );

    if (result != null) {
      debugPrint('✅ 테스트 성공: API가 정상 작동합니다');
      debugPrint('   거리: ${result.distanceInKm}');
      debugPrint('   시간: ${result.durationInMinutes}');
    } else {
      debugPrint('❌ 테스트 실패: API 키 또는 설정 문제일 수 있습니다');
    }
  }
}
