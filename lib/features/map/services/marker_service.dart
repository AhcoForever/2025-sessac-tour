import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import '../constants/map_constants.dart';
import '../../public_data/models/content_info.dart';
import '../../public_data/models/night_spot.dart';

/// 마커 관리를 담당하는 서비스
class MarkerService {
  BitmapDescriptor? _customMarkerIcon;
  BitmapDescriptor? _touristSpotMarkerIcon;
  BitmapDescriptor? _nightSpotMarkerIcon;

  /// 커스텀 마커 아이콘 로드
  Future<BitmapDescriptor> loadCustomMarker({double? zoomLevel}) async {
    final ByteData data = await rootBundle.load(
      MapConstants.dangdangImagePath,
    );
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 1, // 매우 작게 (거의 안 보임)
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List resizedData = byteData!.buffer.asUint8List();

    _customMarkerIcon = BitmapDescriptor.bytes(resizedData);
    return _customMarkerIcon!;
  }

  /// 관광지 마커 아이콘 로드
  BitmapDescriptor loadTouristSpotMarker() {
    _touristSpotMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      MapConstants.touristSpotMarkerHue,
    );
    return _touristSpotMarkerIcon!;
  }

  /// 야경명소 마커 아이콘 로드
  BitmapDescriptor loadNightSpotMarker() {
    _nightSpotMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      MapConstants.nightSpotMarkerHue,
    );
    return _nightSpotMarkerIcon!;
  }

  /// 줌 레벨에 따른 마커 크기 계산
  int calculateMarkerSize(double zoom) {
    final size =
        MapConstants.minMarkerSize +
        ((zoom - MapConstants.minZoom) /
            (MapConstants.maxZoom - MapConstants.minZoom)) *
        (MapConstants.maxMarkerSize - MapConstants.minMarkerSize);
    return size.clamp(MapConstants.minMarkerSize, MapConstants.maxMarkerSize).toInt();
  }

  /// 관광지 마커 세트 생성
  Set<Marker> createTouristSpotMarkers({
    required List<ContentInfo> spots,
    String? selectedDestinationId,
    required void Function(ContentInfo) onTap,
  }) {
    if (_touristSpotMarkerIcon == null) return {};

    final markers = <Marker>{};

    for (var spot in spots) {
      // 위도/경도 정보가 있는지 확인
      if (spot.traffic?.mapPositionX == null ||
          spot.traffic?.mapPositionY == null) {
        continue;
      }

      try {
        final double lat = double.parse(spot.traffic!.mapPositionY!);
        final double lng = double.parse(spot.traffic!.mapPositionX!);
        final position = LatLng(lat, lng);

        // 선택된 목적지는 초록색, 나머지는 빨간색
        final isSelected = selectedDestinationId == spot.cid;
        final markerIcon = isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(
                MapConstants.selectedDestinationMarkerHue)
            : _touristSpotMarkerIcon!;

        final marker = Marker(
          markerId: MarkerId('${MapConstants.touristSpotMarkerPrefix}${spot.cid}'),
          position: position,
          icon: markerIcon,
          onTap: () => onTap(spot),
        );

        markers.add(marker);
        print('✅ 마커 추가: ${spot.postSj} ($lat, $lng)');
      } catch (e) {
        print('❌ 마커 생성 실패 (${spot.postSj}): $e');
      }
    }

    return markers;
  }

  /// 야경명소 마커 세트 생성
  Set<Marker> createNightSpotMarkers({
    required List<NightSpot> spots,
    required void Function(NightSpot) onTap,
  }) {
    if (_nightSpotMarkerIcon == null) return {};

    final markers = <Marker>{};

    for (var spot in spots) {
      // 위도/경도 정보가 있는지 확인
      if (spot.la.isEmpty || spot.lo.isEmpty) {
        continue;
      }

      try {
        final double lat = double.parse(spot.la);
        final double lng = double.parse(spot.lo);
        final position = LatLng(lat, lng);

        final marker = Marker(
          markerId: MarkerId('${MapConstants.nightSpotMarkerPrefix}${spot.num}'),
          position: position,
          icon: _nightSpotMarkerIcon!,
          onTap: () => onTap(spot),
        );

        markers.add(marker);
        print('🌙 야경명소 마커 추가: ${spot.title} ($lat, $lng)');
      } catch (e) {
        print('⚠️ 야경명소 마커 생성 실패 (${spot.title}): $e');
      }
    }

    return markers;
  }

  /// 사용자 위치 마커 생성
  Marker? createUserLocationMarker({
    required double latitude,
    required double longitude,
    required VoidCallback onTap,
  }) {
    if (_customMarkerIcon == null) return null;

    final position = LatLng(latitude, longitude);

    return Marker(
      markerId: const MarkerId(MapConstants.userLocationMarkerId),
      position: position,
      icon: _customMarkerIcon!,
      onTap: onTap,
    );
  }

  /// 현재 마커 크기 가져오기 (UI용)
  double getMarkerSize(double zoom) {
    return calculateMarkerSize(zoom).toDouble();
  }
}
