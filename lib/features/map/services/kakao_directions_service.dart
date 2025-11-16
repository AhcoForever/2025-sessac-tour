import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sessactour/core/config.dart';
import '../models/route_info.dart';

/// Kakao Mobility Directions API 서비스
/// 한국 내 경로 탐색을 제공합니다
class KakaoDirectionsService {
  static const String _baseUrl =
      'https://apis-navi.kakaomobility.com/v1/directions';

  // Kakao REST API 키 (AppConfig에서 로드)
  String get _apiKey => AppConfig.kakaoRestApiKey;

  /// 경로 조회
  ///
  /// [start] 출발지 (위도, 경도)
  /// [goal] 목적지 (위도, 경도)
  /// [priority] 경로 우선순위 (RECOMMEND, TIME, DISTANCE)
  /// [waypoints] 경유지 리스트 (최대 5개, 선택사항)
  Future<RouteInfo?> getRoute({
    required LatLng start,
    required LatLng goal,
    String priority = 'RECOMMEND',
    List<LatLng>? waypoints,
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
      // Kakao API는 경도,위도 순서입니다 (X,Y)
      final queryParams = {
        'origin': '${start.longitude},${start.latitude}',
        'destination': '${goal.longitude},${goal.latitude}',
        'priority': priority,
      };

      // 경유지가 있으면 추가 (최대 5개)
      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointStr = waypoints
            .take(5)
            .map((point) => '${point.longitude},${point.latitude}')
            .join('|');
        queryParams['waypoints'] = waypointStr;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'KakaoAK $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Kakao API는 routes 배열로 응답합니다
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          return _parseDirectionsResponse(data);
        } else {
          debugPrint('❌ Kakao Directions: 경로가 없습니다');
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Kakao Directions: 인증 실패 (API 키 확인 필요)');
        return null;
      } else {
        debugPrint('❌ Kakao Directions: 경로 조회 실패 (${response.statusCode})');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 경로 조회 에러: $e');
      return null;
    }
  }

  /// Kakao Mobility Directions API 응답 파싱
  RouteInfo _parseDirectionsResponse(Map<String, dynamic> data) {
    final routes = data['routes'] as List;
    final route = routes[0] as Map<String, dynamic>;

    // 경로 요약 정보
    final summary = route['summary'] as Map<String, dynamic>;
    final distance = summary['distance'] as int; // 미터 단위
    final duration = summary['duration'] as int; // 초 단위

    // 경로 좌표 추출
    final List<LatLng> path = [];
    final sections = route['sections'] as List;

    for (var section in sections) {
      final roads = section['roads'] as List;
      for (var road in roads) {
        // vertexes는 [경도1, 위도1, 경도2, 위도2, ...] 형식의 1차원 배열
        final vertexes = road['vertexes'] as List;
        for (int i = 0; i < vertexes.length; i += 2) {
          final longitude = (vertexes[i] as num).toDouble();
          final latitude = (vertexes[i + 1] as num).toDouble();
          path.add(LatLng(latitude, longitude));
        }
      }
    }

    // 경로 요약 생성
    final distanceKm = (distance / 1000).toStringAsFixed(1);
    final durationMin = (duration / 60).round();
    final summaryText = '경로 (${distanceKm}km, 약 $durationMin분)';

    return RouteInfo(
      path: path,
      distance: distance,
      duration: duration * 1000, // 밀리초로 변환
      summary: summaryText,
    );
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

}
