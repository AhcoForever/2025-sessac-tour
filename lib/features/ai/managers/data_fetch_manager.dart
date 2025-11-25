import 'package:geolocator/geolocator.dart';
import '../../public_data/models/cultural_event.dart';
import '../../public_data/models/content_list_item.dart';
import '../../public_data/models/park_info.dart';
import '../../public_data/models/cultural_space.dart';
import '../../public_data/services/seoulapi_service.dart';
import '../../public_data/services/visitseoul_api_service.dart';
import '../../public_data/services/weather_api_service.dart';
import '../../map/services/location_service.dart';
import '../services/prompt_builder.dart';
import '../models/chracter.dart';

/// 공공 API 데이터 로딩 및 관리를 담당하는 클래스
class DataFetchManager {
  final SeoulApiService _seoulApiService = SeoulApiService();
  final VisitSeoulApiService _visitSeoulApiService = VisitSeoulApiService();
  final WeatherApiService _weatherApiService = WeatherApiService();
  final LocationService _locationService = LocationService();

  // 데이터
  List<CulturalEvent> _culturalEvents = [];
  List<ContentListItem> _tourContents = [];
  List<ParkInfo> _parkInfos = [];
  List<CulturalSpace> _culturalSpaces = [];
  String? _weatherSummary;
  Position? _currentPosition;
  String? _currentLocation;

  bool _isLoadingData = true;

  // 토큰 절약: 위치 기반 필터링 반경 (미터)
  static const double _filterRadiusMeters = 5000; // 5km

  // Getters
  List<CulturalEvent> get culturalEvents => _culturalEvents;
  List<ContentListItem> get tourContents => _tourContents;
  List<ParkInfo> get parkInfos => _parkInfos;
  List<CulturalSpace> get culturalSpaces => _culturalSpaces;
  String? get weatherSummary => _weatherSummary;
  Position? get currentPosition => _currentPosition;
  String? get currentLocation => _currentLocation;
  bool get isLoadingData => _isLoadingData;

  /// 모든 데이터 로드
  Future<void> loadAllData() async {
    _isLoadingData = true;

    await Future.wait([
      _loadCulturalEvents(),
      _loadTourContents(),
      _loadParkInfo(),
      _loadCulturalSpace(),
      _loadWeather(),
      _loadLocation(),
    ]);

    _isLoadingData = false;
  }

  /// 위치 정보 로드
  Future<void> _loadLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        _currentPosition = position;
        _currentLocation =
            '위도: ${position.latitude.toStringAsFixed(4)}, 경도: ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      // 위치 정보 로드 실패 시 무시
    }
  }

  /// 서울시 문화행사 데이터 로드
  Future<void> _loadCulturalEvents() async {
    try {
      // 서울시 문화행사 20개 가져오기 (토큰 절약)
      final events = await _seoulApiService.getCulturalEvent(
        startIndex: 1,
        endIndex: 20,
      );

      _culturalEvents = events;
      print('✅ 문화행사 ${events.length}개 로드 완료');
    } catch (e) {
      print('❌ 문화행사 로드 실패: $e');
      _culturalEvents = [];
    }
  }

  /// VisitSeoul 관광 콘텐츠 데이터 로드
  Future<void> _loadTourContents() async {
    try {
      // VisitSeoul 관광 콘텐츠 20개 가져오기 (토큰 절약)
      final response = await _visitSeoulApiService.getContentList(
        langCodeId: 'ko',
        sortType: 'latest',
        pageNo: 1,
      );

      if (response != null) {
        // 진행 중인 콘텐츠만 필터링 (토큰 절약: 20개로 제한)
        final ongoingContents = response.data
            .where((content) => content.isOngoing())
            .take(20)
            .toList();

        _tourContents = ongoingContents;
        print('✅ 관광 콘텐츠 ${ongoingContents.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ 관광 콘텐츠 로드 실패: $e');
      _tourContents = [];
    }
  }

  /// 서울시 공원 정보 데이터 로드
  Future<void> _loadParkInfo() async {
    try {
      // 서울시 공원 정보 20개 가져오기 (토큰 절약)
      final response = await _seoulApiService.getParkInfo(
        startIndex: 1,
        endIndex: 20,
      );

      if (response != null && response.result.isSuccess) {
        // 위치 기반 필터링 (5km 이내)
        List<ParkInfo> filteredParks = response.row;

        if (_currentPosition != null) {
          filteredParks = response.row.where((park) {
            try {
              // 좌표를 String에서 double로 파싱
              final parkLat = double.parse(park.latitude);
              final parkLng = double.parse(park.longitude);

              final distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                parkLat,
                parkLng,
              );
              return distance <= _filterRadiusMeters;
            } catch (e) {
              return true; // 좌표 파싱 실패 시 포함
            }
          }).toList();

          print('📍 공원 필터링: ${response.row.length}개 → ${filteredParks.length}개 (5km 이내)');
        }

        _parkInfos = filteredParks;
        print('✅ 공원 정보 ${filteredParks.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ 공원 정보 로드 실패: $e');
      _parkInfos = [];
    }
  }

  /// 서울시 문화 공간 정보 데이터 로드
  Future<void> _loadCulturalSpace() async {
    try {
      // 서울시 문화 공간 정보 20개 가져오기 (토큰 절약)
      final response = await _seoulApiService.getCulturalSpace(
        startIndex: 1,
        endIndex: 20,
      );

      if (response != null && response.result.isSuccess) {
        // 위치 기반 필터링 (5km 이내)
        List<CulturalSpace> filteredSpaces = response.row;

        if (_currentPosition != null) {
          filteredSpaces = response.row.where((space) {
            try {
              // 좌표를 String에서 double로 파싱
              final spaceLat = double.parse(space.latitude);
              final spaceLng = double.parse(space.longitude);

              final distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                spaceLat,
                spaceLng,
              );
              return distance <= _filterRadiusMeters;
            } catch (e) {
              return true; // 좌표 파싱 실패 시 포함
            }
          }).toList();

          print('📍 문화공간 필터링: ${response.row.length}개 → ${filteredSpaces.length}개 (5km 이내)');
        }

        _culturalSpaces = filteredSpaces;
        print('✅ 문화 공간 정보 ${filteredSpaces.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ 문화 공간 정보 로드 실패: $e');
      _culturalSpaces = [];
    }
  }

  /// 기상청 중기예보 정보 로드
  Future<void> _loadWeather() async {
    try {
      // 기상청 중기예보 조회
      final summary = await _weatherApiService.getWeatherSummary();

      _weatherSummary = summary;
      print('✅ 날씨 예보 로드 완료');
    } catch (e) {
      print('❌ 날씨 예보 로드 실패: $e');
      _weatherSummary = null;
    }
  }

  /// 시스템 프롬프트 생성
  String buildSystemPrompt(Character? character) {
    return PromptBuilder.buildSystemPrompt(
      character: character,
      culturalEvents: _culturalEvents,
      tourContents: _tourContents,
      parkInfos: _parkInfos,
      culturalSpaces: _culturalSpaces,
      currentLocation: _currentLocation,
      weatherSummary: _weatherSummary,
    );
  }
}
