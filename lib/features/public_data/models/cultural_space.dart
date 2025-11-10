/// 서울시 문화 공간 정보 모델
class CulturalSpace {
  final String num; // 순번
  final String subjectCode; // 카테고리
  final String facilityName; // 시설명
  final String address; // 주소
  final String district; // 자치구
  final String latitude; // 위도
  final String longitude; // 경도
  final String phone; // 전화번호
  final String? fax; // 팩스
  final String? homepage; // 홈페이지
  final String? openHour; // 운영시간
  final String? entranceFee; // 입장료
  final String? closeDay; // 휴무일
  final String? openDay; // 개관일
  final String? seatCount; // 좌석수
  final String? mainImage; // 이미지
  final String? facilityDescription; // 시설설명
  final String? entranceFree; // 무료/유료
  final String? subway; // 지하철
  final String? busStop; // 버스정류장

  CulturalSpace({
    required this.num,
    required this.subjectCode,
    required this.facilityName,
    required this.address,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.fax,
    this.homepage,
    this.openHour,
    this.entranceFee,
    this.closeDay,
    this.openDay,
    this.seatCount,
    this.mainImage,
    this.facilityDescription,
    this.entranceFree,
    this.subway,
    this.busStop,
  });

  // JSON에서 CulturalSpace 객체 생성
  factory CulturalSpace.fromJson(Map<String, dynamic> json) {
    return CulturalSpace(
      num: json['NUM'] ?? '',
      subjectCode: json['SUBJCODE'] ?? '',
      facilityName: json['FAC_NAME'] ?? '시설명 없음',
      address: json['ADDR'] ?? '',
      district: json['GNGU'] ?? '',
      latitude: json['X_COORD']?.toString() ?? '',
      longitude: json['Y_COORD']?.toString() ?? '',
      phone: json['PHNE'] ?? '',
      fax: json['FAX'],
      homepage: json['HOMEPAGE'],
      openHour: json['OPENHOUR'],
      entranceFee: json['ENTR_FEE'],
      closeDay: json['CLOSEDAY'],
      openDay: json['OPEN_DAY'],
      seatCount: json['SEAT_CNT'],
      mainImage: json['MAIN_IMG'],
      facilityDescription: json['FAC_DESC'],
      entranceFree: json['ENTRFREE'],
      subway: json['SUBWAY'],
      busStop: json['BUSSTOP'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NUM': num,
      'SUBJCODE': subjectCode,
      'FAC_NAME': facilityName,
      'ADDR': address,
      'GNGU': district,
      'X_COORD': latitude,
      'Y_COORD': longitude,
      'PHNE': phone,
      'FAX': fax,
      'HOMEPAGE': homepage,
      'OPENHOUR': openHour,
      'ENTR_FEE': entranceFee,
      'CLOSEDAY': closeDay,
      'OPEN_DAY': openDay,
      'SEAT_CNT': seatCount,
      'MAIN_IMG': mainImage,
      'FAC_DESC': facilityDescription,
      'ENTRFREE': entranceFree,
      'SUBWAY': subway,
      'BUSSTOP': busStop,
    };
  }
}

/// API 응답 모델
class CulturalSpaceResponse {
  final int listTotalCount;
  final ResultCode result;
  final List<CulturalSpace> row;

  CulturalSpaceResponse({
    required this.listTotalCount,
    required this.result,
    required this.row,
  });

  factory CulturalSpaceResponse.fromJson(Map<String, dynamic> json) {
    final culturalSpaceInfo = json['culturalSpaceInfo'];
    return CulturalSpaceResponse(
      listTotalCount: culturalSpaceInfo['list_total_count'] ?? 0,
      result: ResultCode.fromJson(culturalSpaceInfo['RESULT']),
      row: (culturalSpaceInfo['row'] as List?)
              ?.map((item) => CulturalSpace.fromJson(item))
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
