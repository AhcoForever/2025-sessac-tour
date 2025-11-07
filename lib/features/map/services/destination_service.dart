import 'package:geolocator/geolocator.dart';
import '../constants/map_constants.dart';
import '../../public_data/models/content_info.dart';

/// 목적지 관리 및 거리 계산을 담당하는 서비스
class DestinationService {
  /// 두 지점 간의 거리 계산 (미터 단위)
  double calculateDistance({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(
      fromLat,
      fromLng,
      toLat,
      toLng,
    );
  }

  /// ContentInfo의 좌표를 가져와서 현재 위치로부터의 거리 계산
  double? calculateDistanceToDestination({
    required Position currentPosition,
    required ContentInfo destination,
  }) {
    if (destination.traffic?.mapPositionX == null ||
        destination.traffic?.mapPositionY == null) {
      return null;
    }

    try {
      final double destLat =
          double.parse(destination.traffic!.mapPositionY!);
      final double destLng =
          double.parse(destination.traffic!.mapPositionX!);

      return calculateDistance(
        fromLat: currentPosition.latitude,
        fromLng: currentPosition.longitude,
        toLat: destLat,
        toLng: destLng,
      );
    } catch (e) {
      print('❌ 거리 계산 실패: $e');
      return null;
    }
  }

  /// 목적지에 도착했는지 확인
  bool hasArrived(double distance) {
    return distance <= MapConstants.arrivalThreshold;
  }

  /// 거리를 사람이 읽기 쉬운 형식으로 변환
  String formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toInt()}m';
    }
    return '${(distance / 1000).toStringAsFixed(1)}km';
  }
}
