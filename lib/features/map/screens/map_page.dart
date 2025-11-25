import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';
import '../managers/location_tracker.dart';
import '../managers/marker_manager.dart';
import '../managers/route_manager.dart';
import '../managers/destination_manager.dart';
import '../managers/data_loader.dart';
import '../constants/map_constants.dart';
import 'widgets/marker_info_window.dart';
import 'widgets/location_fab.dart';
import 'widgets/floating_marker.dart';
import 'widgets/tourist_spot_bottom_sheet.dart';
import 'widgets/distance_indicator_widget.dart';
import 'widgets/arrival_dialog.dart';
import 'widgets/night_spot_bottom_sheet.dart';
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
  // Managers
  final LocationTracker _locationTracker = LocationTracker();
  final MarkerManager _markerManager = MarkerManager();
  final RouteManager _routeManager = RouteManager();
  final DestinationManager _destinationManager = DestinationManager();
  final DataLoader _dataLoader = DataLoader();

  GoogleMapController? mapController;
  bool _mapReady = false;
  bool _hasTriedShowingRoute = false;

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
        _destinationManager.setAiDestination(destination);
      }
    }
  }

  /// 지도 초기화
  Future<void> _initializeMap() async {
    // 1. 마커 아이콘 로드
    await _markerManager.loadCustomMarker();
    _markerManager.loadTouristSpotMarker();
    _markerManager.loadNightSpotMarker();

    // 2. 데이터 로드 (비동기)
    _loadData();

    // 3. 현재 위치 가져오기
    await _getCurrentLocation();

    // 4. 실시간 위치 추적 시작
    _startLocationTracking();
  }

  /// 데이터 로드
  Future<void> _loadData() async {
    await _dataLoader.loadAllData();
    if (mounted) {
      setState(() {
        _addTouristSpotMarkers();
        _addNightSpotMarkers();
      });
    }
  }

  /// 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    final position = await _locationTracker.getCurrentLocation();

    if (position == null) {
      final errorMessage = await _locationTracker.getPermissionErrorMessage();
      if (mounted && errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } else {
      _markerManager.addUserLocationMarker(position);
      _markerManager.updateMarkerScreenPosition(position);
    }

    if (mounted) setState(() {});
    _tryShowAiRoute();
  }

  /// 실시간 위치 추적 시작
  void _startLocationTracking() {
    _locationTracker.startLocationTracking(
      onPositionUpdate: (position) {
        if (!mounted) return;

        setState(() {
          _markerManager.addUserLocationMarker(position);
          _markerManager.updateMarkerScreenPosition(position);

          // 목적지가 설정되어 있으면 거리 계산 및 도착 확인
          if (_destinationManager.selectedDestination != null) {
            _destinationManager.calculateDistance(position);

            if (_destinationManager.checkArrival(position)) {
              _showArrivalDialog();
            }
          }
        });

        // 지도를 새 위치로 이동
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      },
    );
  }

  /// 관광지 마커 추가
  void _addTouristSpotMarkers() {
    _markerManager.addTouristSpotMarkers(
      spots: _dataLoader.touristSpots,
      selectedDestinationId: _destinationManager.selectedDestination?.cid,
      onTap: _showTouristSpotDetails,
    );
  }

  /// 야경명소 마커 추가
  void _addNightSpotMarkers() {
    _markerManager.addNightSpotMarkers(
      spots: _dataLoader.nightSpots,
      onTap: _showNightSpotDetails,
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

  /// 야경명소 상세 정보 바텀 시트 표시
  void _showNightSpotDetails(NightSpot spot) {
    NightSpotBottomSheet.show(context, spot: spot);
  }

  /// 목적지 설정
  void _setDestination(ContentInfo destination) {
    _destinationManager.setDestination(destination);

    setState(() {
      _addTouristSpotMarkers(); // 선택된 목적지는 초록색으로
    });

    final currentPosition = _locationTracker.currentPosition;
    if (currentPosition != null) {
      _destinationManager.calculateDistance(currentPosition);
      _showRouteToDestination(destination);
    }
  }

  /// 목적지까지의 경로 표시
  Future<void> _showRouteToDestination(ContentInfo destination) async {
    final currentPosition = _locationTracker.currentPosition;

    if (currentPosition == null) {
      _showSnackBar('현재 위치를 가져오는 중입니다...', Colors.orange);
      return;
    }

    if (destination.traffic?.mapPositionY == null ||
        destination.traffic?.mapPositionX == null) {
      _showSnackBar('목적지의 위치 정보가 없습니다.', Colors.red);
      return;
    }

    try {
      final destLat = double.parse(destination.traffic!.mapPositionY!);
      final destLng = double.parse(destination.traffic!.mapPositionX!);

      final start = LatLng(currentPosition.latitude, currentPosition.longitude);
      final goal = LatLng(destLat, destLng);

      final routeInfo = await _routeManager.showRoute(
        start: start,
        goal: goal,
        routeId: 'marker_route',
      );

      if (routeInfo != null && mounted) {
        setState(() {});
        _showSnackBar(
          '${destination.postSj}\n${routeInfo.distanceInKm}, ${routeInfo.durationInMinutes}',
          Colors.green[700]!,
          icon: Icons.navigation,
        );
      } else if (mounted) {
        _showSnackBar('${destination.postSj}까지의 경로를 찾을 수 없습니다.', Colors.orange);
      }
    } catch (e) {
      debugPrint('❌ 경로 표시 에러: $e');
      if (mounted) {
        _showSnackBar('경로를 표시하는 중 오류가 발생했습니다.', Colors.red);
      }
    }
  }

  /// 도착 알림 다이얼로그
  void _showArrivalDialog() {
    _destinationManager.markArrivalDialogShown();

    final destInfo = _destinationManager.getDestinationInfo();
    if (destInfo == null) return;

    ArrivalDialog.show(
      context,
      destinationName: destInfo['name'],
      onTakePhoto: () => _navigateToPhotoCapture(destInfo),
    );
  }

  /// 카메라 페이지로 이동
  void _navigateToPhotoCapture(Map<String, dynamic> destInfo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoCapturePage(
          destinationName: destInfo['name'],
          destinationAddress: destInfo['address'],
          latitude: destInfo['latitude'],
          longitude: destInfo['longitude'],
          destinationId: destInfo['id'],
        ),
      ),
    );
  }

  /// 지도 생성 콜백
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _markerManager.setMapController(controller);
    _routeManager.setMapController(controller);

    final currentPosition = _locationTracker.currentPosition;
    if (currentPosition != null) {
      _markerManager.updateMarkerScreenPosition(currentPosition);
    }

    _mapReady = true;
    _tryShowAiRoute();
  }

  /// 카메라 이동 시 처리
  void _onCameraMove(CameraPosition position) {
    _markerManager.customInfoWindowController.onCameraMove!();

    final currentPosition = _locationTracker.currentPosition;
    if (currentPosition != null) {
      // 화면 좌표 업데이트 후 UI 갱신
      _markerManager.updateMarkerScreenPosition(currentPosition).then((_) {
        if (mounted) setState(() {});
      });
    }

    // 줌 레벨 변화 처리
    _markerManager.handleCameraMove(position, (newSize) {
      if (mounted) {
        setState(() {});
        final pos = _locationTracker.currentPosition;
        if (pos != null) {
          _markerManager.addUserLocationMarker(pos);
        }
      }
    });
  }

  /// 현재 위치로 카메라 이동
  Future<void> _moveToCurrentLocation() async {
    var position = _locationTracker.currentPosition;

    if (position == null) {
      position = await _locationTracker.getCurrentLocation();
      if (mounted) setState(() {});
    }

    if (position != null && mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: MapConstants.currentLocationZoom,
            tilt: MapConstants.defaultTilt,
          ),
        ),
      );
    }
  }

  /// AI 추천 경로 표시
  Future<void> _showAiRecommendedRoute() async {
    final aiDestination = _destinationManager.aiDestination;
    final currentPosition = _locationTracker.currentPosition;

    if (aiDestination == null ||
        aiDestination.latitude == null ||
        aiDestination.longitude == null ||
        currentPosition == null) {
      debugPrint('❌ 경로 표시 불가: 목적지 또는 현재 위치 정보 없음');
      return;
    }

    final start = LatLng(currentPosition.latitude, currentPosition.longitude);
    final goal = LatLng(aiDestination.latitude!, aiDestination.longitude!);

    final routeInfo = await _routeManager.showRoute(
      start: start,
      goal: goal,
      routeId: 'ai_route',
    );

    if (routeInfo != null && mounted) {
      setState(() {
        _markerManager.addAiDestinationMarker(
          position: goal,
          title: aiDestination.title,
          snippet: aiDestination.address ?? '목적지',
        );
      });

      _showSnackBar(
        '경로 안내: ${routeInfo.distanceInKm}, ${routeInfo.durationInMinutes}',
        Colors.blue[700]!,
      );
    } else {
      debugPrint('❌ 경로 조회 실패');
      if (mounted) {
        _showSnackBar('경로를 찾을 수 없습니다. 로그를 확인해주세요.', Colors.red);
      }
    }
  }

  /// AI 경로 표시 시도
  void _tryShowAiRoute() {
    if (_destinationManager.aiDestination != null &&
        _locationTracker.currentPosition != null &&
        _mapReady &&
        !_hasTriedShowingRoute) {
      _hasTriedShowingRoute = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        _showAiRecommendedRoute();
      });
    }
  }

  /// AI 경로 초기화
  void _clearAiRoute() {
    setState(() {
      _destinationManager.clearAiDestination();
      _routeManager.removeRoute('ai_route');
      _markerManager.removeMarker('ai_destination');
      _hasTriedShowingRoute = false;
    });

    if (_locationTracker.currentPosition != null) {
      _moveToCurrentLocation();
    }
  }

  /// SnackBar 표시 헬퍼
  void _showSnackBar(String message, Color backgroundColor, {IconData? icon}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: icon != null
            ? Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              )
            : Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = _locationTracker.currentPosition;
    final isLoading = _locationTracker.isLoadingLocation;

    // 로딩 중
    if (isLoading && currentPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initialPosition = currentPosition != null
        ? LatLng(currentPosition.latitude, currentPosition.longitude)
        : MapConstants.seoulCenter;

    final aiDestination = _destinationManager.aiDestination;
    final routeInfo = _routeManager.routeInfo;
    final selectedDestination = _destinationManager.selectedDestination;
    final distanceToDestination = _destinationManager.distanceToDestination;
    final markerScreenPosition = _markerManager.markerScreenPosition;
    final currentMarkerSize = _markerManager.currentMarkerSize;

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
            markers: _markerManager.markers,
            polylines: _routeManager.polylines,
            buildingsEnabled: true,
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            onTap: (_) {
              _markerManager.customInfoWindowController.hideInfoWindow!();
            },
            onCameraMove: _onCameraMove,
          ),

          // 애니메이션 마커
          if (currentPosition != null && markerScreenPosition != null)
            Positioned(
              left: markerScreenPosition.dx - (currentMarkerSize / 2),
              top: markerScreenPosition.dy - (currentMarkerSize / 2),
              child: FloatingMarker(
                imagePath: MapConstants.dangdangImagePath,
                size: currentMarkerSize,
                onTap: () {
                  final markerPos = LatLng(
                    currentPosition.latitude,
                    currentPosition.longitude,
                  );
                  _markerManager.customInfoWindowController.addInfoWindow!(
                    const MarkerInfoWindow(message: MapConstants.markerTapMessage),
                    markerPos,
                  );
                },
              ),
            ),

          CustomInfoWindow(
            controller: _markerManager.customInfoWindowController,
            height: MapConstants.customInfoWindowHeight,
            width: MapConstants.customInfoWindowWidth,
            offset: MapConstants.customInfoWindowOffset,
          ),

          // 목적지까지 거리 표시
          if (selectedDestination != null && distanceToDestination != null)
            DistanceIndicatorWidget(
              destinationName: selectedDestination.postSj,
              distance: distanceToDestination,
            ),

          // AI 추천 경로 안내
          if (routeInfo != null && aiDestination != null)
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
                          Icon(Icons.navigation,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aiDestination.title,
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
                          Icon(Icons.directions_walk,
                              size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${routeInfo.distanceInKm} · ${routeInfo.durationInMinutes}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
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
        isLoading: isLoading,
      ),
    );
  }

  @override
  void dispose() {
    _locationTracker.dispose();
    _markerManager.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
