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
}
