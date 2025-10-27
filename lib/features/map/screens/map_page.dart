import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:custom_info_window/custom_info_window.dart';
import '../services/location_service.dart';
import 'widgets/marker_info_window.dart';
import 'widgets/location_fab.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // LocationService 인스턴스
  final LocationService _locationService = LocationService();
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  GoogleMapController? mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _customMarkerIcon;
  double _currentZoom = 18.0;
  double _previousZoom = 18.0;

  final LatLng _center = const LatLng(37.5665, 126.9780);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  /// 지도 초기화 (순차적으로 실행)
  Future<void> _initializeMap() async {
    // 1. 먼저 커스텀 마커 로드
    await _loadCustomMarker();
    // 2. 마커 로드 완료 후 현재 위치 가져오기
    await _getCurrentLocation();
  }

  /// 줌 레벨에 따른 마커 크기 계산
  int _calculateMarkerSize(double zoom) {
    // 줌 레벨에 따라 마커 크기를 동적으로 계산
    // 줌 10: 40px, 줌 15: 80px, 줌 18: 120px, 줌 20: 160px
    const minSize = 40;
    const maxSize = 200;
    const minZoom = 10.0;
    const maxZoom = 21.0;

    final size =
        minSize +
        ((zoom - minZoom) / (maxZoom - minZoom)) * (maxSize - minSize);
    return size.clamp(minSize, maxSize).toInt();
  }

  /// 커스텀 마커 아이콘 로드
  Future<void> _loadCustomMarker({double? zoomLevel}) async {
    final zoom = zoomLevel ?? _currentZoom;
    final markerSize = _calculateMarkerSize(zoom);

    final ByteData data = await rootBundle.load(
      'assets/images/seoul_characters/dangdang-smile.png',
    );
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: markerSize,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List resizedData = byteData!.buffer.asUint8List();

    _customMarkerIcon = await BitmapDescriptor.bytes(resizedData);

    // 마커가 업데이트되었으면 현재 위치 마커도 업데이트
    if (_currentPosition != null) {
      _addUserLocationMarker(_currentPosition!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _customInfoWindowController.googleMapController = controller;
  }

  /// 카메라 이동 시 줌 레벨 변화 감지
  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;

    // 줌 레벨이 1.0 이상 변경되었을 때만 마커 크기 업데이트
    if ((_currentZoom - _previousZoom).abs() >= 1.0) {
      _previousZoom = _currentZoom;
      _loadCustomMarker(zoomLevel: _currentZoom);
    }
  }

  /// 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    // LocationService를 통해 위치 가져오기
    final position = await _locationService.getCurrentLocation();

    if (position == null) {
      // 권한 에러 메시지 표시
      final errorMessage = await _locationService.getPermissionErrorMessage();
      if (mounted && errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } else {
      // 현재 위치에 마커 추가
      _addUserLocationMarker(position);
    }

    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
    });
  }

  /// 사용자 위치에 마커 추가
  void _addUserLocationMarker(Position position) {
    if (_customMarkerIcon == null) return;

    final markerPosition = LatLng(position.latitude, position.longitude);

    final marker = Marker(
      markerId: const MarkerId('user_location'),
      position: markerPosition,
      icon: _customMarkerIcon!,
      onTap: () {
        _customInfoWindowController.addInfoWindow!(
          const MarkerInfoWindow(message: '댕댕청룡이 응원해요! 화이팅!'),
          markerPosition,
        );
      },
    );

    setState(() {
      // 기존 마커 제거 후 새로 추가
      _markers.removeWhere(
        (m) => m.markerId == const MarkerId('user_location'),
      );
      _markers.add(marker);
    });
  }

  /// 카메라를 사용자 위치로 이동
  Future<void> _moveToCurrentLocation() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (_currentPosition != null && mapController != null) {
      final position = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 19.0, tilt: 45.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 위치 정보를 가져오는 동안 로딩 표시
    if (_isLoadingLocation && _currentPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 위치 정보가 있으면 해당 위치로, 없으면 서울 중심으로
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _center;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 18.0,
              tilt: 45.0,
              bearing: 30.0,
            ),
            markers: _markers,
            buildingsEnabled: true,
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            onTap: (position) {
              _customInfoWindowController.hideInfoWindow!();
            },
            onCameraMove: (position) {
              _customInfoWindowController.onCameraMove!();
              _onCameraMove(position);
            },
          ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 60,
            width: 280,
            offset: 150,
          ),
        ],
      ),
      floatingActionButton: LocationFab(
        onPressed: _moveToCurrentLocation,
        isLoading: _isLoadingLocation,
      ),
    );
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
