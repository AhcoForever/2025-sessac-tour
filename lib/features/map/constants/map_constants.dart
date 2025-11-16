import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 지도 페이지에서 사용하는 상수들
abstract final class MapConstants {
  // ========== 지도 설정 ==========

  /// 서울 중심 좌표 (기본 위치)
  static const LatLng seoulCenter = LatLng(37.5665, 126.9780);

  /// 기본 줌 레벨
  static const double defaultZoom = 18.0;

  /// 현재 위치로 이동 시 줌 레벨
  static const double currentLocationZoom = 19.0;

  /// 기본 지도 기울기
  static const double defaultTilt = 45.0;

  /// 기본 지도 회전 각도
  static const double defaultBearing = 30.0;

  // ========== 마커 설정 ==========

  /// 기본 마커 크기 (픽셀)
  static const double defaultMarkerSize = 90.0;

  /// 최소 마커 크기 (픽셀)
  static const int minMarkerSize = 30;

  /// 최대 마커 크기 (픽셀)
  static const int maxMarkerSize = 150;

  /// 최소 줌 레벨 (마커 크기 계산용)
  static const double minZoom = 10.0;

  /// 최대 줌 레벨 (마커 크기 계산용)
  static const double maxZoom = 21.0;

  /// 줌 레벨 변경 감지 임계값
  static const double zoomChangeThreshold = 1.0;

  // ========== 마커 색상 ==========

  /// 관광지 마커 색상
  static const double touristSpotMarkerHue = BitmapDescriptor.hueRed;

  /// 야경명소 마커 색상
  static const double nightSpotMarkerHue = BitmapDescriptor.hueBlue;

  /// 선택된 목적지 마커 색상
  static const double selectedDestinationMarkerHue = BitmapDescriptor.hueGreen;

  // ========== 위치 추적 설정 ==========

  /// 위치 업데이트 최소 거리 (미터)
  static const int locationUpdateDistance = 5;

  /// 목적지 도착 인식 거리 (미터)
  static const double arrivalThreshold = 50.0;

  // ========== API 설정 ==========

  /// 관광지 데이터 로드 개수
  static const int touristSpotsLoadCount = 50;

  /// 야경명소 데이터 시작 인덱스
  static const int nightSpotsStartIndex = 1;

  /// 야경명소 데이터 종료 인덱스
  static const int nightSpotsEndIndex = 100;

  // ========== UI 설정 ==========

  /// 커스텀 정보창 높이
  static const double customInfoWindowHeight = 60.0;

  /// 커스텀 정보창 너비
  static const double customInfoWindowWidth = 280.0;

  /// 커스텀 정보창 오프셋
  static const double customInfoWindowOffset = 50.0;

  /// 바텀 시트 최대 높이 비율 (화면 높이의 70%)
  static const double bottomSheetMaxHeightRatio = 0.7;

  // ========== 마커 ID 접두사 ==========

  /// 사용자 위치 마커 ID
  static const String userLocationMarkerId = 'user_location';

  /// 관광지 마커 ID 접두사
  static const String touristSpotMarkerPrefix = 'tourist_';

  /// 야경명소 마커 ID 접두사
  static const String nightSpotMarkerPrefix = 'nightspot_';

  // ========== 이미지 경로 ==========

  /// 댕댕청룡 이미지 경로
  static const String dangdangImagePath = 'assets/images/seoul_characters/dangdang-smile.png';

  // ========== 메시지 ==========

  /// 마커 탭 시 표시 메시지
  static const String markerTapMessage = '댕댕청룡이 응원해요! 화이팅!';
}
