// lib/model/map_marker_data.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 범용 지도 마커 데이터 모델
///
/// ParkourSpot 같은 특정 도메인 모델 대신 사용하는 범용 마커 데이터
/// 다른 프로젝트에서도 재사용 가능
class MapMarkerData {
  /// 마커 고유 ID
  final String id;

  /// 마커 제목 (필수)
  final String title;

  /// 마커 부제목 (선택)
  final String? subtitle;

  /// 마커 위치 좌표
  final LatLng position;

  /// 추가 데이터 저장용 (프로젝트별로 필요한 데이터를 여기에 저장)
  /// 예: {'imageUrl': '...', 'rating': 4.5, 'category': 'restaurant'}
  final Map<String, dynamic>? extraData;

  const MapMarkerData({
    required this.id,
    required this.title,
    required this.position,
    this.subtitle,
    this.extraData,
  });

  /// JSON으로부터 생성
  factory MapMarkerData.fromJson(Map<String, dynamic> json) {
    return MapMarkerData(
      id: json['id'] as String,
      title: json['title'] as String,
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      subtitle: json['subtitle'] as String?,
      extraData: json['extraData'] as Map<String, dynamic>?,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'extraData': extraData,
    };
  }

  /// 복사본 생성
  MapMarkerData copyWith({
    String? id,
    String? title,
    String? subtitle,
    LatLng? position,
    Map<String, dynamic>? extraData,
  }) {
    return MapMarkerData(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      position: position ?? this.position,
      extraData: extraData ?? this.extraData,
    );
  }

  @override
  String toString() => 'MapMarkerData(id: $id, title: $title, position: $position)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MapMarkerData &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}
