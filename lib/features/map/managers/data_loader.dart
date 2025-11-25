import '../../public_data/services/visitseoul_api_service.dart';
import '../../public_data/services/seoulapi_service.dart';
import '../../public_data/models/content_info.dart';
import '../../public_data/models/night_spot.dart';
import '../constants/map_constants.dart';

/// 관광지 및 야경명소 데이터 로딩을 담당하는 클래스
class DataLoader {
  final VisitSeoulApiService _visitSeoulApiService = VisitSeoulApiService();
  final SeoulApiService _seoulApiService = SeoulApiService();

  List<ContentInfo> _touristSpots = [];
  List<NightSpot> _nightSpots = [];

  // Getters
  List<ContentInfo> get touristSpots => _touristSpots;
  List<NightSpot> get nightSpots => _nightSpots;

  /// 관광지 데이터 가져오기
  Future<List<ContentInfo>> loadTouristSpots() async {
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

        _touristSpots = contents;
        return contents;
      } else {
        print('⚠️ 관광지 데이터가 없습니다.');
        return [];
      }
    } catch (e) {
      print('❌ 관광지 데이터 로드 실패: $e');
      return [];
    }
  }

  /// 야경명소 데이터 가져오기
  Future<List<NightSpot>> loadNightSpots() async {
    try {
      print('🌙 야경명소 데이터 로딩 시작');
      final response = await _seoulApiService.getNightSpots(
        startIndex: MapConstants.nightSpotsStartIndex,
        endIndex: MapConstants.nightSpotsEndIndex,
      );

      if (response != null && response.row.isNotEmpty) {
        print('✅ 야경명소 ${response.row.length}개 로드 성공');

        _nightSpots = response.row;
        return response.row;
      } else {
        print('⚠️ 야경명소 데이터가 없습니다.');
        return [];
      }
    } catch (e) {
      print('❌ 야경명소 데이터 로드 실패: $e');
      return [];
    }
  }

  /// 모든 데이터 로드
  Future<void> loadAllData() async {
    await Future.wait([
      loadTouristSpots(),
      loadNightSpots(),
    ]);
  }
}
