// lib/features/map/services/location_service.dart
import 'package:geolocator/geolocator.dart';

/// 위치 관련 기능을 담당하는 서비스 클래스
class LocationService {
  Position? _currentPosition;

  /// 현재 저장된 위치 정보
  Position? get currentPosition => _currentPosition;

  /// 위치 권한 확인 및 요청
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 활성화 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// 현재 위치 가져오기
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      return null;
    }
  }

  /// 권한 에러 메시지 반환
  Future<String?> getPermissionErrorMessage() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return '위치 서비스가 비활성화되어 있습니다.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      return '위치 권한이 거부되었습니다.';
    }

    if (permission == LocationPermission.deniedForever) {
      return '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.';
    }

    return null;
  }
}
