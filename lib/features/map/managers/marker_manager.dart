import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:custom_info_window/custom_info_window.dart';
import '../services/marker_service.dart';
import '../constants/map_constants.dart';
import '../screens/widgets/marker_info_window.dart';
import '../../public_data/models/content_info.dart';
import '../../public_data/models/night_spot.dart';

/// 모든 마커 생성 및 관리를 담당하는 클래스
class MarkerManager {
  final MarkerService _markerService = MarkerService();
  final CustomInfoWindowController customInfoWindowController =
      CustomInfoWindowController();

  final Set<Marker> _markers = {};
  double _currentZoom = MapConstants.defaultZoom;
  double _previousZoom = MapConstants.defaultZoom;
  double _currentMarkerSize = MapConstants.defaultMarkerSize;
  Offset? _markerScreenPosition;

  GoogleMapController? _mapController;

  // Getters
  Set<Marker> get markers => _markers;
  double get currentMarkerSize => _currentMarkerSize;
  Offset? get markerScreenPosition => _markerScreenPosition;

  /// 지도 컨트롤러 설정
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    customInfoWindowController.googleMapController = controller;
  }

  /// 관광지 마커 아이콘 로드
  void loadTouristSpotMarker() {
    _markerService.loadTouristSpotMarker();
  }

  /// 야경명소 마커 아이콘 로드
  void loadNightSpotMarker() {
    _markerService.loadNightSpotMarker();
  }

  /// 커스텀 마커 아이콘 로드
  Future<void> loadCustomMarker({double? zoomLevel}) async {
    final zoom = zoomLevel ?? _currentZoom;

    _currentMarkerSize = _markerService.getMarkerSize(zoom);

    await _markerService.loadCustomMarker(zoomLevel: zoom);
  }

  /// 사용자 위치 마커 추가
  Marker? addUserLocationMarker(Position position) {
    final markerPosition = LatLng(position.latitude, position.longitude);

    final marker = _markerService.createUserLocationMarker(
      latitude: position.latitude,
      longitude: position.longitude,
      onTap: () {
        customInfoWindowController.addInfoWindow!(
          const MarkerInfoWindow(message: MapConstants.markerTapMessage),
          markerPosition,
        );
      },
    );

    if (marker == null) return null;

    // 기존 마커 제거 후 새로 추가
    _markers.removeWhere(
      (m) => m.markerId == const MarkerId(MapConstants.userLocationMarkerId),
    );
    _markers.add(marker);

    return marker;
  }

  /// 관광지 마커 추가
  void addTouristSpotMarkers({
    required List<ContentInfo> spots,
    String? selectedDestinationId,
    required Function(ContentInfo) onTap,
  }) {
    final newMarkers = _markerService.createTouristSpotMarkers(
      spots: spots,
      selectedDestinationId: selectedDestinationId,
      onTap: onTap,
    );

    // 기존 관광지 마커들 제거
    _markers.removeWhere(
      (m) => m.markerId.value.startsWith(MapConstants.touristSpotMarkerPrefix),
    );
    // 새 마커 추가
    _markers.addAll(newMarkers);
  }

  /// 야경명소 마커 추가
  void addNightSpotMarkers({
    required List<NightSpot> spots,
    required Function(NightSpot) onTap,
  }) {
    final newMarkers = _markerService.createNightSpotMarkers(
      spots: spots,
      onTap: onTap,
    );

    // 기존 야경명소 마커들 제거
    _markers.removeWhere(
      (m) => m.markerId.value.startsWith(MapConstants.nightSpotMarkerPrefix),
    );
    // 새 마커 추가
    _markers.addAll(newMarkers);
  }

  /// AI 목적지 마커 추가
  void addAiDestinationMarker({
    required LatLng position,
    required String title,
    String? snippet,
  }) {
    final marker = Marker(
      markerId: const MarkerId('ai_destination'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet ?? '목적지',
      ),
    );

    // 기존 AI 목적지 마커 제거 후 추가
    _markers.removeWhere((m) => m.markerId.value == 'ai_destination');
    _markers.add(marker);
  }

  /// 특정 마커 제거
  void removeMarker(String markerId) {
    _markers.removeWhere((m) => m.markerId.value == markerId);
  }

  /// 마커의 화면 좌표 업데이트
  Future<Offset?> updateMarkerScreenPosition(Position position) async {
    if (_mapController == null) return null;

    final latLng = LatLng(
      position.latitude,
      position.longitude,
    );

    try {
      final screenCoordinate = await _mapController!.getScreenCoordinate(latLng);
      _markerScreenPosition = Offset(
        screenCoordinate.x.toDouble(),
        screenCoordinate.y.toDouble(),
      );
      return _markerScreenPosition;
    } catch (e) {
      // 에러 무시 (맵이 아직 준비되지 않은 경우)
      return null;
    }
  }

  /// 카메라 이동 시 줌 레벨 변화 처리
  Future<bool> handleCameraMove(
    CameraPosition position,
    Function(double) onMarkerSizeChanged,
  ) async {
    _currentZoom = position.zoom;

    // 줌 레벨이 임계값 이상 변경되었을 때만 true 반환
    if ((_currentZoom - _previousZoom).abs() >= MapConstants.zoomChangeThreshold) {
      _previousZoom = _currentZoom;
      await loadCustomMarker(zoomLevel: _currentZoom);
      onMarkerSizeChanged(_currentMarkerSize);
      return true;
    }
    return false;
  }

  /// 리소스 정리
  void dispose() {
    customInfoWindowController.dispose();
  }
}
