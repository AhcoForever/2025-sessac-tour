import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../constants/map_constants.dart';

/// 위치 추적 및 관리를 담당하는 클래스
class LocationTracker {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoadingLocation = true;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;

  /// 현재 위치 가져오기
  Future<Position?> getCurrentLocation() async {
    _isLoadingLocation = true;

    // LocationService를 통해 위치 가져오기
    final position = await _locationService.getCurrentLocation();

    _currentPosition = position;
    _isLoadingLocation = false;

    return position;
  }

  /// 위치 권한 에러 메시지 가져오기
  Future<String?> getPermissionErrorMessage() async {
    return await _locationService.getPermissionErrorMessage();
  }

  /// 실시간 위치 추적 시작
  void startLocationTracking({
    required Function(Position) onPositionUpdate,
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: MapConstants.locationUpdateDistance,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = position;
      onPositionUpdate(position);
    });
  }

  /// 위치 추적 중지
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// 리소스 정리
  void dispose() {
    stopLocationTracking();
  }
}
