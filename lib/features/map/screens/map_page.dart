import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:custom_info_window/custom_info_window.dart';
import '../services/location_service.dart';
import '../services/marker_service.dart';
import '../services/destination_service.dart';
import '../services/google_routes_service.dart';
import '../models/route_info.dart';
import '../constants/map_constants.dart';
import 'widgets/marker_info_window.dart';
import 'widgets/location_fab.dart';
import 'widgets/floating_marker.dart';
import 'widgets/tourist_spot_bottom_sheet.dart';
import 'widgets/distance_indicator_widget.dart';
import 'widgets/arrival_dialog.dart';
import 'widgets/night_spot_bottom_sheet.dart';
import '../../public_data/services/visitseoul_api_service.dart';
import '../../public_data/services/seoulapi_service.dart';
import '../../public_data/models/content_info.dart';
import '../../public_data/models/night_spot.dart';
import '../../camera/screens/photo_capture_page.dart';
import '../../ai/models/recommendation.dart';

class MapPage extends StatefulWidget {
  final Map<String, dynamic>? routeParams;

  const MapPage({super.key, this.routeParams});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Services
  final LocationService _locationService = LocationService();
  final MarkerService _markerService = MarkerService();
  final DestinationService _destinationService = DestinationService();
  final GoogleRoutesService _routesService = GoogleRoutesService();
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  final VisitSeoulApiService _visitSeoulApiService = VisitSeoulApiService();
  final SeoulApiService _seoulApiService = SeoulApiService();

  GoogleMapController? mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {}; // 경로 표시용
  double _currentZoom = MapConstants.defaultZoom;
  double _previousZoom = MapConstants.defaultZoom;
  StreamSubscription<Position>? _positionStreamSubscription;
  double _currentMarkerSize = MapConstants.defaultMarkerSize;
  Offset? _markerScreenPosition;
  List<ContentInfo> _touristSpots = [];
  List<NightSpot> _nightSpots = [];

  // 목적지 관련
  ContentInfo? _selectedDestination;
  double? _distanceToDestination;
  bool _hasShownArrivalDialog = false;

  // AI 추천 경로 관련
  Recommendation? _aiDestination;
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;
  bool _mapReady = false; // 지도가 준비되었는지 여부
  bool _hasTriedShowingRoute = false; // 경로 표시를 시도했는지 여부

  @override
  void initState() {
    super.initState();
    _checkRouteParams();
    _initializeMap();
  }

  /// AI 채팅에서 전달된 경로 파라미터 확인
  void _checkRouteParams() {
    if (widget.routeParams != null) {
      final destination = widget.routeParams!['destination'] as Recommendation?;
      final showRoute = widget.routeParams!['showRoute'] as bool? ?? false;

      if (destination != null && showRoute) {
        _aiDestination = destination;
        debugPrint('🎯 AI 추천 목적지: ${destination.title}');
        debugPrint('📍 좌표: ${destination.latitude}, ${destination.longitude}');
      }
    }
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
    // 8. AI 추천 경로는 onMapCreated에서 표시 (mapController가 준비된 후)
  }

  /// 관광지 마커 아이콘 로드 (기본 빨간색 마커 사용)
  void _loadTouristSpotMarker() {
    _markerService.loadTouristSpotMarker();
  }

  /// 야경명소 마커 아이콘 로드 (파란색 마커 사용)
  void _loadNightSpotMarker() {
    _markerService.loadNightSpotMarker();
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

        // 각 컨텐츠의 상세 정보 가져오기
        final cidList = response.data
            .take(MapConstants.touristSpotsLoadCount)
            .map((item) => item.cid)
            .toList();
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
        startIndex: MapConstants.nightSpotsStartIndex,
        endIndex: MapConstants.nightSpotsEndIndex,
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
    final newMarkers = _markerService.createTouristSpotMarkers(
      spots: _touristSpots,
      selectedDestinationId: _selectedDestination?.cid,
      onTap: _showTouristSpotDetails,
    );

    setState(() {
      // 기존 관광지 마커들 제거
      _markers.removeWhere(
        (m) => m.markerId.value.startsWith(MapConstants.touristSpotMarkerPrefix),
      );
      // 새 마커 추가
      _markers.addAll(newMarkers);
    });
  }

  /// 야경명소 마커 추가
  void _addNightSpotMarkers() {
    final newMarkers = _markerService.createNightSpotMarkers(
      spots: _nightSpots,
      onTap: _showNightSpotDetails,
    );

    setState(() {
      // 기존 야경명소 마커들 제거
      _markers.removeWhere(
        (m) => m.markerId.value.startsWith(MapConstants.nightSpotMarkerPrefix),
      );
      // 새 마커 추가
      _markers.addAll(newMarkers);
    });
  }

  /// 야경명소 상세 정보 바텀 시트 표시
  void _showNightSpotDetails(NightSpot spot) {
    NightSpotBottomSheet.show(context, spot: spot);
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

    final distance = _destinationService.calculateDistanceToDestination(
      currentPosition: _currentPosition!,
      destination: _selectedDestination!,
    );

    if (distance == null) return;

    setState(() {
      _distanceToDestination = distance;
    });

    // 도착 확인
    if (_destinationService.hasArrived(distance) && !_hasShownArrivalDialog) {
      _showArrivalDialog();
    }
  }

  /// 도착 알림 다이얼로그
  void _showArrivalDialog() {
    setState(() {
      _hasShownArrivalDialog = true;
    });

    ArrivalDialog.show(
      context,
      destinationName: _selectedDestination!.postSj,
      onTakePhoto: _navigateToPhotoCapture,
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
      distanceFilter: MapConstants.locationUpdateDistance,
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

  /// 커스텀 마커 아이콘 로드
  Future<void> _loadCustomMarker({double? zoomLevel}) async {
    final zoom = zoomLevel ?? _currentZoom;

    setState(() {
      _currentMarkerSize = _markerService.getMarkerSize(zoom);
    });

    await _markerService.loadCustomMarker(zoomLevel: zoom);

    // 마커가 업데이트되었으면 현재 위치 마커도 업데이트
    if (_currentPosition != null) {
      _addUserLocationMarker(_currentPosition!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _customInfoWindowController.googleMapController = controller;
    _updateMarkerScreenPosition();

    _mapReady = true;
    _tryShowAiRoute();
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

    // 줌 레벨이 임계값 이상 변경되었을 때만 마커 크기 업데이트
    if ((_currentZoom - _previousZoom).abs() >= MapConstants.zoomChangeThreshold) {
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

    // 위치가 준비되었으면 AI 경로 표시 시도
    _tryShowAiRoute();
  }

  /// 사용자 위치에 마커 추가
  void _addUserLocationMarker(Position position) {
    final markerPosition = LatLng(position.latitude, position.longitude);

    final marker = _markerService.createUserLocationMarker(
      latitude: position.latitude,
      longitude: position.longitude,
      onTap: () {
        _customInfoWindowController.addInfoWindow!(
          const MarkerInfoWindow(message: MapConstants.markerTapMessage),
          markerPosition,
        );
      },
    );

    if (marker == null) return;

    setState(() {
      // 기존 마커 제거 후 새로 추가
      _markers.removeWhere(
        (m) => m.markerId == const MarkerId(MapConstants.userLocationMarkerId),
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
          CameraPosition(
            target: position,
            zoom: MapConstants.currentLocationZoom,
            tilt: MapConstants.defaultTilt,
          ),
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
        : MapConstants.seoulCenter;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: MapConstants.defaultZoom,
              tilt: MapConstants.defaultTilt,
              bearing: MapConstants.defaultBearing,
            ),
            markers: _markers,
            polylines: _polylines, // AI 추천 경로 표시
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
                imagePath: MapConstants.dangdangImagePath,
                size: _currentMarkerSize,
                onTap: () {
                  if (_currentPosition != null) {
                    final markerPosition = LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    );
                    _customInfoWindowController.addInfoWindow!(
                      const MarkerInfoWindow(message: MapConstants.markerTapMessage),
                      markerPosition,
                    );
                  }
                },
              ),
            ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: MapConstants.customInfoWindowHeight,
            width: MapConstants.customInfoWindowWidth,
            offset: MapConstants.customInfoWindowOffset,
          ),

          // 목적지까지 거리 표시
          if (_selectedDestination != null && _distanceToDestination != null)
            DistanceIndicatorWidget(
              destinationName: _selectedDestination!.postSj,
              distance: _distanceToDestination!,
            ),

          // AI 추천 경로 안내
          if (_routeInfo != null && _aiDestination != null)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.navigation,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _aiDestination!.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _clearAiRoute,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_routeInfo!.distanceInKm} · ${_routeInfo!.durationInMinutes}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 디버그용 테스트 버튼
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'test_api',
              onPressed: _testDirectionsApi,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.bug_report),
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

  // ==================== AI 추천 경로 관련 메서드 ====================

  /// AI 추천 경로 표시
  Future<void> _showAiRecommendedRoute() async {
    if (_aiDestination == null ||
        _aiDestination!.latitude == null ||
        _aiDestination!.longitude == null ||
        _currentPosition == null) {
      debugPrint('❌ 경로 표시 불가: 목적지 또는 현재 위치 정보 없음');
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      final start = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final goal = LatLng(
        _aiDestination!.latitude!,
        _aiDestination!.longitude!,
      );

      debugPrint('🚀 경로 조회 시작');
      debugPrint('   출발 좌표: (${start.latitude}, ${start.longitude})');
      debugPrint('   도착 좌표: (${goal.latitude}, ${goal.longitude})');

      // 직선 거리 계산
      final straightDistance = _routesService.calculateDistance(start, goal);
      debugPrint('   직선 거리: ${(straightDistance / 1000).toStringAsFixed(2)}km');

      // Google Directions API로 경로 조회
      final routeInfo = await _routesService.getWalkingRoute(
        start: start,
        goal: goal,
      );

      if (routeInfo != null && mounted) {
        setState(() {
          _routeInfo = routeInfo;
          _isLoadingRoute = false;
        });

        // 경로 Polyline 그리기
        _drawRoute(routeInfo.path);

        // 목적지 마커 추가
        _addAiDestinationMarker(goal);

        // 카메라를 경로가 보이도록 조정
        _fitRouteBounds(routeInfo.path);

        debugPrint('✅ 경로 표시 완료: ${routeInfo.distanceInKm}, ${routeInfo.durationInMinutes}');

        // 사용자에게 성공 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('경로 안내: ${routeInfo.distanceInKm}, ${routeInfo.durationInMinutes}'),
              backgroundColor: Colors.blue[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('❌ 경로 조회 실패');
        setState(() => _isLoadingRoute = false);

        // 사용자에게 실패 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('경로를 찾을 수 없습니다. 로그를 확인해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 경로 표시 에러: $e');
      setState(() => _isLoadingRoute = false);
    }
  }

  /// 경로를 Polyline으로 그리기
  void _drawRoute(List<LatLng> path) {
    final polyline = Polyline(
      polylineId: const PolylineId('ai_route'),
      points: path,
      color: Colors.blue,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      geodesic: true,
    );

    setState(() {
      _polylines.clear();
      _polylines.add(polyline);
    });
  }

  /// AI 목적지 마커 추가
  void _addAiDestinationMarker(LatLng position) {
    final marker = Marker(
      markerId: const MarkerId('ai_destination'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: _aiDestination!.title,
        snippet: _aiDestination!.address ?? '목적지',
      ),
    );

    setState(() {
      // 기존 AI 목적지 마커 제거 후 추가
      _markers.removeWhere((m) => m.markerId.value == 'ai_destination');
      _markers.add(marker);
    });
  }

  /// 경로가 모두 보이도록 카메라 조정
  void _fitRouteBounds(List<LatLng> path) {
    if (path.isEmpty || mapController == null) return;

    double minLat = path.first.latitude;
    double maxLat = path.first.latitude;
    double minLng = path.first.longitude;
    double maxLng = path.first.longitude;

    for (final point in path) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100픽셀 패딩
    );
  }

  /// AI 경로 표시 시도 (지도와 위치가 모두 준비되었을 때)
  void _tryShowAiRoute() {
    if (_aiDestination != null &&
        _currentPosition != null &&
        _mapReady &&
        !_hasTriedShowingRoute) {
      _hasTriedShowingRoute = true;
      // 약간의 딜레이를 주어 지도가 완전히 준비되도록 함
      Future.delayed(const Duration(milliseconds: 500), () {
        _showAiRecommendedRoute();
      });
    }
  }

  /// AI 경로 초기화
  void _clearAiRoute() {
    setState(() {
      _routeInfo = null;
      _aiDestination = null;
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value == 'ai_destination');
      _hasTriedShowingRoute = false;
    });

    // 현재 위치로 카메라 이동
    if (_currentPosition != null) {
      _moveToCurrentLocation();
    }
  }

  /// 디버그용: API 테스트
  Future<void> _testDirectionsApi() async {
    debugPrint('🧪 ========== API 테스트 시작 ==========');

    // 테스트 1: 알려진 좌표로 API 동작 확인
    await _routesService.testWithKnownLocations();

    // 테스트 2: 현재 위치에서 가까운 관광지로 경로 찾기
    if (_currentPosition != null && _touristSpots.isNotEmpty) {
      final nearbySpot = _touristSpots.first;
      if (nearbySpot.traffic?.mapPositionY != null &&
          nearbySpot.traffic?.mapPositionX != null) {
        final spotLat = double.tryParse(nearbySpot.traffic!.mapPositionY!);
        final spotLng = double.tryParse(nearbySpot.traffic!.mapPositionX!);

        if (spotLat != null && spotLng != null) {
          debugPrint('\n🧪 테스트 2: 현재 위치 -> ${nearbySpot.postSj}');
          debugPrint('   출발: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
          debugPrint('   도착: $spotLat, $spotLng');

          final result = await _routesService.getWalkingRoute(
            start: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            goal: LatLng(spotLat, spotLng),
          );

          if (result != null) {
            debugPrint('✅ 테스트 2 성공');
          } else {
            debugPrint('❌ 테스트 2 실패');
          }
        }
      }
    }

    debugPrint('🧪 ========== API 테스트 종료 ==========');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API 테스트 완료. 로그를 확인하세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _customInfoWindowController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
