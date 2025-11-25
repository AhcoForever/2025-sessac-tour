import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/kakao_directions_service.dart';
import '../models/route_info.dart';

/// 경로 조회 및 표시를 담당하는 클래스
class RouteManager {
  final KakaoDirectionsService _directionsService = KakaoDirectionsService();

  final Set<Polyline> _polylines = {};
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;

  GoogleMapController? _mapController;

  // Getters
  Set<Polyline> get polylines => _polylines;
  RouteInfo? get routeInfo => _routeInfo;
  bool get isLoadingRoute => _isLoadingRoute;

  /// 지도 컨트롤러 설정
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// 경로 조회
  Future<RouteInfo?> getRoute({
    required LatLng start,
    required LatLng goal,
    String priority = 'RECOMMEND',
  }) async {
    _isLoadingRoute = true;

    try {
      final routeInfo = await _directionsService.getRoute(
        start: start,
        goal: goal,
        priority: priority,
      );

      _routeInfo = routeInfo;
      _isLoadingRoute = false;

      return routeInfo;
    } catch (e) {
      debugPrint('❌ 경로 조회 실패: $e');
      _isLoadingRoute = false;
      return null;
    }
  }

  /// 경로를 Polyline으로 그리기
  void drawRoute(List<LatLng> path, {String routeId = 'ai_route'}) {
    final polyline = Polyline(
      polylineId: PolylineId(routeId),
      points: path,
      color: Colors.blue,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      geodesic: true,
    );

    // 같은 ID의 경로만 제거 (다른 경로는 유지)
    _polylines.removeWhere((p) => p.polylineId.value == routeId);
    _polylines.add(polyline);
  }

  /// 특정 경로 제거
  void removeRoute(String routeId) {
    _polylines.removeWhere((p) => p.polylineId.value == routeId);
  }

  /// 모든 경로 제거
  void clearAllRoutes() {
    _polylines.clear();
    _routeInfo = null;
  }

  /// 경로가 모두 보이도록 카메라 조정
  void fitRouteBounds(List<LatLng> path, {int padding = 100}) {
    if (path.isEmpty || _mapController == null) return;

    double minLat = path.first.latitude;
    double maxLat = path.first.latitude;
    double minLng = path.first.longitude;
    double maxLng = path.first.longitude;

    for (final point in path) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding.toDouble()),
    );
  }

  /// 경로 표시 (조회 + 그리기 + 카메라 조정)
  Future<RouteInfo?> showRoute({
    required LatLng start,
    required LatLng goal,
    String routeId = 'ai_route',
    String priority = 'RECOMMEND',
    int cameraPadding = 100,
  }) async {
    final routeInfo = await getRoute(
      start: start,
      goal: goal,
      priority: priority,
    );

    if (routeInfo != null) {
      drawRoute(routeInfo.path, routeId: routeId);
      fitRouteBounds(routeInfo.path, padding: cameraPadding);
    }

    return routeInfo;
  }
}
