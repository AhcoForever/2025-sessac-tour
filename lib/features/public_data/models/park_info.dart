/// 서울시 주요 공원현황 정보 모델
class ParkInfo {
  final String sn; // 순번
  final String parkName; // 공원명
  final String parkOutline; // 공원 개요
  final String area; // 면적
  final String openDate; // 개원일
  final String mainFacility; // 주요 시설
  final String mainPlant; // 주요 식물
  final String visitRoad; // 찾아가는 길
  final String utilizationRef; // 이용 참고사항
  final String? imageUrl; // 이미지 URL
  final String region; // 지역(구)
  final String parkAddress; // 주소
  final String manageDept; // 관리 부서
  final String telNo; // 전화번호
  final String latitude; // 위도
  final String longitude; // 경도
  final String? url; // 홈페이지 URL

  ParkInfo({
    required this.sn,
    required this.parkName,
    required this.parkOutline,
    required this.area,
    required this.openDate,
    required this.mainFacility,
    required this.mainPlant,
    required this.visitRoad,
    required this.utilizationRef,
    this.imageUrl,
    required this.region,
    required this.parkAddress,
    required this.manageDept,
    required this.telNo,
    required this.latitude,
    required this.longitude,
    this.url,
  });

  // JSON에서 ParkInfo 객체 생성
  factory ParkInfo.fromJson(Map<String, dynamic> json) {
    return ParkInfo(
      sn: json['SN'] ?? '',
      parkName: json['PARK_NM'] ?? '공원명 없음',
      parkOutline: json['PARK_OTLN'] ?? '',
      area: json['AREA'] ?? '',
      openDate: json['OPEN_YMD'] ?? '',
      mainFacility: json['MAIN_FCLT'] ?? '',
      mainPlant: json['MAIN_PLNT'] ?? '',
      visitRoad: json['VST_ROAD'] ?? '',
      utilizationRef: json['UTZTN_REF'] ?? '',
      imageUrl: json['IMG'],
      region: json['RGN'] ?? '',
      parkAddress: json['PARK_ADDR'] ?? '',
      manageDept: json['MNG_DEPT'] ?? '',
      telNo: json['TELNO'] ?? '',
      latitude: json['YCRD']?.toString() ?? '',
      longitude: json['XCRD']?.toString() ?? '',
      url: json['URL'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SN': sn,
      'PARK_NM': parkName,
      'PARK_OTLN': parkOutline,
      'AREA': area,
      'OPEN_YMD': openDate,
      'MAIN_FCLT': mainFacility,
      'MAIN_PLNT': mainPlant,
      'VST_ROAD': visitRoad,
      'UTZTN_REF': utilizationRef,
      'IMG': imageUrl,
      'RGN': region,
      'PARK_ADDR': parkAddress,
      'MNG_DEPT': manageDept,
      'TELNO': telNo,
      'YCRD': latitude,
      'XCRD': longitude,
      'URL': url,
    };
  }
}

/// API 응답 모델
class ParkInfoResponse {
  final int listTotalCount;
  final ResultCode result;
  final List<ParkInfo> row;

  ParkInfoResponse({
    required this.listTotalCount,
    required this.result,
    required this.row,
  });

  factory ParkInfoResponse.fromJson(Map<String, dynamic> json) {
    final searchParkInfoService = json['SearchParkInfoService'];
    return ParkInfoResponse(
      listTotalCount: searchParkInfoService['list_total_count'] ?? 0,
      result: ResultCode.fromJson(searchParkInfoService['RESULT']),
      row: (searchParkInfoService['row'] as List?)
              ?.map((item) => ParkInfo.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// API 결과 코드
class ResultCode {
  final String code;
  final String message;

  ResultCode({
    required this.code,
    required this.message,
  });

  factory ResultCode.fromJson(Map<String, dynamic> json) {
    return ResultCode(
      code: json['CODE'] ?? '',
      message: json['MESSAGE'] ?? '',
    );
  }

  bool get isSuccess => code == 'INFO-000';
}
