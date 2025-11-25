import 'package:geolocator/geolocator.dart';
import '../services/destination_service.dart';
import '../../public_data/models/content_info.dart';
import '../../ai/models/recommendation.dart';

/// 목적지 관리 및 도착 감지를 담당하는 클래스
class DestinationManager {
  final DestinationService _destinationService = DestinationService();

  ContentInfo? _selectedDestination;
  Recommendation? _aiDestination;
  double? _distanceToDestination;
  bool _hasShownArrivalDialog = false;

  // Getters
  ContentInfo? get selectedDestination => _selectedDestination;
  Recommendation? get aiDestination => _aiDestination;
  double? get distanceToDestination => _distanceToDestination;
  bool get hasShownArrivalDialog => _hasShownArrivalDialog;

  /// 목적지 설정 (관광지)
  void setDestination(ContentInfo destination) {
    _selectedDestination = destination;
    _hasShownArrivalDialog = false;
    _distanceToDestination = null;
  }

  /// AI 추천 목적지 설정
  void setAiDestination(Recommendation destination) {
    _aiDestination = destination;
  }

  /// AI 목적지 초기화
  void clearAiDestination() {
    _aiDestination = null;
  }

  /// 목적지 초기화
  void clearDestination() {
    _selectedDestination = null;
    _distanceToDestination = null;
    _hasShownArrivalDialog = false;
  }

  /// 목적지까지의 거리 계산
  double? calculateDistance(Position currentPosition) {
    if (_selectedDestination == null) return null;

    final distance = _destinationService.calculateDistanceToDestination(
      currentPosition: currentPosition,
      destination: _selectedDestination!,
    );

    if (distance != null) {
      _distanceToDestination = distance;
    }

    return distance;
  }

  /// 도착 여부 확인
  bool checkArrival(Position currentPosition) {
    final distance = calculateDistance(currentPosition);

    if (distance == null) return false;

    // 도착했고 아직 알림을 보여주지 않았으면 true 반환
    if (_destinationService.hasArrived(distance) && !_hasShownArrivalDialog) {
      return true;
    }

    return false;
  }

  /// 도착 알림 표시 완료 플래그 설정
  void markArrivalDialogShown() {
    _hasShownArrivalDialog = true;
  }

  /// 목적지 정보 가져오기
  Map<String, dynamic>? getDestinationInfo() {
    if (_selectedDestination == null) return null;

    final address = _selectedDestination!.traffic?.newAdres ??
        _selectedDestination!.traffic?.adres ??
        '주소 정보 없음';

    final lat = _selectedDestination!.traffic?.mapPositionY != null
        ? double.tryParse(_selectedDestination!.traffic!.mapPositionY!) ?? 0.0
        : 0.0;
    final lng = _selectedDestination!.traffic?.mapPositionX != null
        ? double.tryParse(_selectedDestination!.traffic!.mapPositionX!) ?? 0.0
        : 0.0;

    return {
      'name': _selectedDestination!.postSj,
      'address': address,
      'latitude': lat,
      'longitude': lng,
      'id': _selectedDestination!.cid,
    };
  }
}
