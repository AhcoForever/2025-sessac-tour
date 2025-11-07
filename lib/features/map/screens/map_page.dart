import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:custom_info_window/custom_info_window.dart';
import '../services/location_service.dart';
import 'widgets/marker_info_window.dart';
import 'widgets/location_fab.dart';
import 'widgets/floating_marker.dart';
import 'widgets/tourist_spot_bottom_sheet.dart';
import '../../public_data/services/visitseoul_api_service.dart';
import '../../public_data/services/seoulapi_service.dart';
import '../../public_data/models/content_info.dart';
import '../../public_data/models/night_spot.dart';
import '../../camera/screens/photo_capture_page.dart';

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
  final VisitSeoulApiService _visitSeoulApiService = VisitSeoulApiService();
  final SeoulApiService _seoulApiService = SeoulApiService();

  GoogleMapController? mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _customMarkerIcon;
  BitmapDescriptor? _touristSpotMarkerIcon;
  BitmapDescriptor? _nightSpotMarkerIcon;
  double _currentZoom = 18.0;
  double _previousZoom = 18.0;
  StreamSubscription<Position>? _positionStreamSubscription;
  double _currentMarkerSize = 90.0;
  Offset? _markerScreenPosition;
  List<ContentInfo> _touristSpots = [];
  List<NightSpot> _nightSpots = [];

  // 목적지 관련
  ContentInfo? _selectedDestination;
  double? _distanceToDestination;
  bool _hasShownArrivalDialog = false;

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
    // 2. 관광지 마커 아이콘 로드
    _loadTouristSpotMarker();
    // 3. 야경명소 마커 아이콘 로드
    _loadNightSpotMarker();
    // 4. 관광지 데이터 가져오기 (비동기로 실행하여 지도 로딩 차단 방지)
    _loadTouristSpots();
    // 5. 야경명소 데이터 가져오기
    _loadNightSpots();
    // 6. 마커 로드 완료 후 현재 위치 가져오기
    await _getCurrentLocation();
    // 7. 실시간 위치 추적 시작
    _startLocationTracking();
  }

  /// 관광지 마커 아이콘 로드 (기본 빨간색 마커 사용)
  void _loadTouristSpotMarker() {
    _touristSpotMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
  }

  /// 야경명소 마커 아이콘 로드 (파란색 마커 사용)
  void _loadNightSpotMarker() {
    _nightSpotMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueBlue,
    );
  }

  /// 관광지 데이터 가져오기
  Future<void> _loadTouristSpots() async {
    try {
      print('🔵 관광지 데이터 로딩 시작');
      final response = await _visitSeoulApiService.getContentList(
        pageNo: 1,
        langCodeId: 'ko',
      );

      if (response != null && response.data.isNotEmpty) {
        print('✅ 관광지 ${response.data.length}개 로드 성공');

        // 각 컨텐츠의 상세 정보 가져오기 (처음 10개만)
        final cidList = response.data.take(10).map((item) => item.cid).toList();
        final contents = await _visitSeoulApiService.getMultipleContents(cidList);

        setState(() {
          _touristSpots = contents;
        });

        // 관광지 마커 추가
        _addTouristSpotMarkers();
      } else {
        print('⚠️ 관광지 데이터가 없습니다.');
      }
    } catch (e) {
      print('❌ 관광지 데이터 로드 실패: $e');
    }
  }

  /// 야경명소 데이터 가져오기
  Future<void> _loadNightSpots() async {
    try {
      print('🌙 야경명소 데이터 로딩 시작');
      final response = await _seoulApiService.getNightSpots(
        startIndex: 1,
        endIndex: 100,
      );

      if (response != null && response.row.isNotEmpty) {
        print('✅ 야경명소 ${response.row.length}개 로드 성공');

        setState(() {
          _nightSpots = response.row;
        });

        // 야경명소 마커 추가
        _addNightSpotMarkers();
      } else {
        print('⚠️ 야경명소 데이터가 없습니다.');
      }
    } catch (e) {
      print('❌ 야경명소 데이터 로드 실패: $e');
    }
  }

  /// 관광지 마커 추가
  void _addTouristSpotMarkers() {
    if (_touristSpotMarkerIcon == null) return;

    // 기존 관광지 마커들 제거
    setState(() {
      _markers.removeWhere(
        (m) => m.markerId.value.startsWith('tourist_'),
      );
    });

    for (var spot in _touristSpots) {
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
        final isSelected = _selectedDestination?.cid == spot.cid;
        final markerIcon = isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : _touristSpotMarkerIcon!;

        final marker = Marker(
          markerId: MarkerId('tourist_${spot.cid}'),
          position: position,
          icon: markerIcon,
          onTap: () => _showTouristSpotDetails(spot),
        );

        setState(() {
          _markers.add(marker);
        });
        print('✅ 마커 추가: ${spot.postSj} ($lat, $lng)');
      } catch (e) {
        print('❌ 마커 생성 실패 (${spot.postSj}): $e');
      }
    }
  }

  /// 야경명소 마커 추가
  void _addNightSpotMarkers() {
    if (_nightSpotMarkerIcon == null) return;

    // 기존 야경명소 마커들 제거
    setState(() {
      _markers.removeWhere(
        (m) => m.markerId.value.startsWith('nightspot_'),
      );
    });

    for (var spot in _nightSpots) {
      // 위도/경도 정보가 있는지 확인
      if (spot.la.isEmpty || spot.lo.isEmpty) {
        continue;
      }

      try {
        final double lat = double.parse(spot.la);
        final double lng = double.parse(spot.lo);
        final position = LatLng(lat, lng);

        final marker = Marker(
          markerId: MarkerId('nightspot_${spot.num}'),
          position: position,
          icon: _nightSpotMarkerIcon!,
          onTap: () => _showNightSpotDetails(spot),
        );

        setState(() {
          _markers.add(marker);
        });
        print('🌙 야경명소 마커 추가: ${spot.title} ($lat, $lng)');
      } catch (e) {
        print('⚠️ 야경명소 마커 생성 실패 (${spot.title}): $e');
      }
    }
  }

  /// 야경명소 상세 정보 바텀 시트 표시
  void _showNightSpotDetails(NightSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리 태그
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🌙 ${spot.subjectCd}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 제목
                    Text(
                      spot.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 주소
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            spot.addr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (spot.telNo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            spot.telNo,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // 운영시간
                    if (spot.operatingTime.isNotEmpty) ...[
                      _buildInfoRow('운영시간', spot.operatingTime),
                      const SizedBox(height: 12),
                    ],
                    // 입장료
                    if (spot.entrFee.isNotEmpty) ...[
                      _buildInfoRow('입장료', spot.entrFee),
                      const SizedBox(height: 12),
                    ],
                    // 교통편
                    if (spot.subway.isNotEmpty) ...[
                      _buildInfoRow('🚇 지하철', spot.subway),
                      const SizedBox(height: 12),
                    ],
                    if (spot.bus.isNotEmpty) ...[
                      _buildInfoRow('🚌 버스', spot.bus),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// 관광지 상세 정보 바텀 시트 표시
  void _showTouristSpotDetails(ContentInfo spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TouristSpotBottomSheet(
        spot: spot,
        onSetDestination: () => _setDestination(spot),
      ),
    );
  }

  /// 목적지 설정
  void _setDestination(ContentInfo destination) {
    setState(() {
      _selectedDestination = destination;
      _hasShownArrivalDialog = false;
      _distanceToDestination = null;
    });

    // 관광지 마커 재생성 (선택된 목적지는 초록색으로)
    _addTouristSpotMarkers();

    // 사용자에게 알림
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '목적지 설정: ${destination.postSj}\n도착 시 사진을 찍을 수 있어요!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 4),
      ),
    );

    // 목적지까지의 거리 계산
    if (_currentPosition != null) {
      _calculateDistance();
    }
  }

  /// 목적지까지의 거리 계산
  void _calculateDistance() {
    if (_selectedDestination == null || _currentPosition == null) return;

    if (_selectedDestination!.traffic?.mapPositionX == null ||
        _selectedDestination!.traffic?.mapPositionY == null) {
      return;
    }

    try {
      final double destLat =
          double.parse(_selectedDestination!.traffic!.mapPositionY!);
      final double destLng =
          double.parse(_selectedDestination!.traffic!.mapPositionX!);

      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        destLat,
        destLng,
      );

      setState(() {
        _distanceToDestination = distance;
      });

      // 50m 이내 도달 확인
      if (distance <= 50 && !_hasShownArrivalDialog) {
        _showArrivalDialog();
      }
    } catch (e) {
      print('❌ 거리 계산 실패: $e');
    }
  }

  /// 도착 알림 다이얼로그
  void _showArrivalDialog() {
    setState(() {
      _hasShownArrivalDialog = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber[700], size: 28),
            const SizedBox(width: 8),
            const Text('도착했어요! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedDestination!.postSj}에 도착하셨습니다!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              '5분 이내에 인증샷을 찍어주세요.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '사진은 마이페이지 보관함에 저장됩니다.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPhotoCapture();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, size: 20),
                SizedBox(width: 6),
                Text('사진 찍기'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 카메라 페이지로 이동
  void _navigateToPhotoCapture() {
    if (_selectedDestination == null) return;

    // 주소 정보 가져오기
    final address = _selectedDestination!.traffic?.newAdres ??
        _selectedDestination!.traffic?.adres ??
        '주소 정보 없음';

    // 좌표 정보 가져오기
    final lat = _selectedDestination!.traffic?.mapPositionY != null
        ? double.tryParse(_selectedDestination!.traffic!.mapPositionY!) ?? 0.0
        : 0.0;
    final lng = _selectedDestination!.traffic?.mapPositionX != null
        ? double.tryParse(_selectedDestination!.traffic!.mapPositionX!) ?? 0.0
        : 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoCapturePage(
          destinationName: _selectedDestination!.postSj,
          destinationAddress: address,
          latitude: lat,
          longitude: lng,
          destinationId: _selectedDestination!.cid,
        ),
      ),
    );
  }

  /// 실시간 위치 추적 시작
  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 5미터 이상 이동 시 업데이트
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      // 마커 위치 업데이트
      _addUserLocationMarker(position);

      // 마커 화면 좌표 업데이트
      _updateMarkerScreenPosition();

      // 목적지가 설정되어 있으면 거리 계산
      if (_selectedDestination != null) {
        _calculateDistance();
      }

      // 지도를 새 위치로 부드럽게 이동
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    });
  }

  /// 줌 레벨에 따른 마커 크기 계산
  int _calculateMarkerSize(double zoom) {
    // 줌 레벨에 따라 마커 크기를 동적으로 계산
    // 줌 10: 30px, 줌 15: 60px, 줌 18: 90px, 줌 20: 120px
    const minSize = 30;
    const maxSize = 150;
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

    setState(() {
      _currentMarkerSize = markerSize.toDouble();
    });

    final ByteData data = await rootBundle.load(
      'assets/images/seoul_characters/dangdang-smile.png',
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

    _customMarkerIcon = await BitmapDescriptor.bytes(resizedData);

    // 마커가 업데이트되었으면 현재 위치 마커도 업데이트
    if (_currentPosition != null) {
      _addUserLocationMarker(_currentPosition!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _customInfoWindowController.googleMapController = controller;
    _updateMarkerScreenPosition();
  }

  /// 마커의 화면 좌표 업데이트
  Future<void> _updateMarkerScreenPosition() async {
    if (mapController == null || _currentPosition == null) return;

    final latLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    try {
      final screenCoordinate = await mapController!.getScreenCoordinate(latLng);
      setState(() {
        _markerScreenPosition = Offset(
          screenCoordinate.x.toDouble(),
          screenCoordinate.y.toDouble(),
        );
      });
    } catch (e) {
      // 에러 무시 (맵이 아직 준비되지 않은 경우)
    }
  }

  /// 카메라 이동 시 줌 레벨 변화 감지
  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;

    // 마커 화면 좌표 업데이트
    _updateMarkerScreenPosition();

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
      // 마커 화면 좌표 업데이트
      _updateMarkerScreenPosition();
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
          // 애니메이션 마커 (GPS 위치에 고정)
          if (_currentPosition != null && _markerScreenPosition != null)
            Positioned(
              left: _markerScreenPosition!.dx - (_currentMarkerSize / 2),
              top: _markerScreenPosition!.dy - (_currentMarkerSize / 2),
              child: FloatingMarker(
                imagePath: 'assets/images/seoul_characters/dangdang-smile.png',
                size: _currentMarkerSize,
                onTap: () {
                  if (_currentPosition != null) {
                    final markerPosition = LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    );
                    _customInfoWindowController.addInfoWindow!(
                      const MarkerInfoWindow(message: '댕댕청룡이 응원해요! 화이팅!'),
                      markerPosition,
                    );
                  }
                },
              ),
            ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 60,
            width: 280,
            offset: 50,
          ),

          // 목적지까지 거리 표시
          if (_selectedDestination != null && _distanceToDestination != null)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.navigation,
                          color: Colors.green[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDestination!.postSj,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _distanceToDestination! < 1000
                                      ? '${_distanceToDestination!.toInt()}m'
                                      : '${(_distanceToDestination! / 1000).toStringAsFixed(1)}km',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _distanceToDestination! <= 50
                                        ? Colors.green[700]
                                        : Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _distanceToDestination! <= 50
                                      ? '도착!'
                                      : '남음',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_distanceToDestination! <= 50)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
                          size: 28,
                        ),
                    ],
                  ),
                ),
              ),
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
    _positionStreamSubscription?.cancel();
    _customInfoWindowController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
