import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 네이버 Directions API 경로 정보
class RouteInfo {
  final List<LatLng> path; // 경로 좌표들
  final int distance; // 거리 (미터)
  final int duration; // 소요 시간 (밀리초)
  final String summary; // 경로 요약

  RouteInfo({
    required this.path,
    required this.distance,
    required this.duration,
    required this.summary,
  });

  /// 거리를 km 단위로 변환
  String get distanceInKm {
    return '${(distance / 1000).toStringAsFixed(1)}km';
  }

  /// 소요 시간을 분 단위로 변환
  String get durationInMinutes {
    final minutes = (duration / 60000).round();
    if (minutes < 60) {
      return '$minutes분';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours시간 ${remainingMinutes}분';
    }
  }

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>;
    final traoptimal = route['traoptimal'] as List<dynamic>;

    if (traoptimal.isEmpty) {
      throw Exception('경로를 찾을 수 없습니다');
    }

    final firstRoute = traoptimal[0] as Map<String, dynamic>;
    final summary = firstRoute['summary'] as Map<String, dynamic>;
    final pathData = firstRoute['path'] as List<dynamic>;

    // 경로 좌표 파싱
    final path = pathData.map((coord) {
      final point = coord as List<dynamic>;
      return LatLng(
        (point[1] as num).toDouble(), // latitude
        (point[0] as num).toDouble(), // longitude
      );
    }).toList();

    return RouteInfo(
      path: path,
      distance: summary['distance'] as int,
      duration: summary['duration'] as int,
      summary: summary['start']?['name'] ?? '출발지',
    );
  }
}
