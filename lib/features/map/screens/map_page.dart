import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // LocationService 인스턴스
  final LocationService _locationService = LocationService();

  GoogleMapController? mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  final LatLng _center = const LatLng(37.5665, 126.9780);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }

    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
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
          CameraPosition(
            target: position,
            zoom: 19.0,
            tilt: 45.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 위치 정보를 가져오는 동안 로딩 표시
    if (_isLoadingLocation && _currentPosition == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 위치 정보가 있으면 해당 위치로, 없으면 서울 중심으로
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _center;

    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: 18.0,
          tilt: 45.0,
          bearing: 30.0,
        ),
        buildingsEnabled: true,
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoadingLocation ? null : _moveToCurrentLocation,
        tooltip: '내 위치로 이동',
        child: _isLoadingLocation
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
