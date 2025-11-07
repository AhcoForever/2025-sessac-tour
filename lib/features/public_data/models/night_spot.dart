/// 서울시 야경명소 정보 모델
class NightSpot {
  final double num;
  final String subjectCd; // 카테고리
  final String title; // 명소명
  final String addr; // 주소
  final String la; // 위도
  final String lo; // 경도
  final String telNo; // 전화번호
  final String url; // 홈페이지 URL
  final String operatingTime; // 운영시간
  final String freeYn; // 무료/유료 여부
  final String entrFee; // 입장료
  final String contents; // 상세설명
  final String subway; // 지하철 정보
  final String bus; // 버스 정보
  final String parkingInfo; // 주차 정보
  final String regDate; // 등록일
  final String modDate; // 수정일

  NightSpot({
    required this.num,
    required this.subjectCd,
    required this.title,
    required this.addr,
    required this.la,
    required this.lo,
    required this.telNo,
    required this.url,
    required this.operatingTime,
    required this.freeYn,
    required this.entrFee,
    required this.contents,
    required this.subway,
    required this.bus,
    required this.parkingInfo,
    required this.regDate,
    required this.modDate,
  });

  factory NightSpot.fromJson(Map<String, dynamic> json) {
    return NightSpot(
      num: (json['NUM'] ?? 0).toDouble(),
      subjectCd: json['SUBJECT_CD'] ?? '',
      title: json['TITLE'] ?? '',
      addr: json['ADDR'] ?? '',
      la: json['LA']?.toString() ?? '',
      lo: json['LO']?.toString() ?? '',
      telNo: json['TEL_NO'] ?? '',
      url: json['URL'] ?? '',
      operatingTime: json['OPERATING_TIME'] ?? '',
      freeYn: json['FREE_YN'] ?? '',
      entrFee: json['ENTR_FEE'] ?? '',
      contents: json['CONTENTS'] ?? '',
      subway: json['SUBWAY'] ?? '',
      bus: json['BUS'] ?? '',
      parkingInfo: json['PARKING_INFO'] ?? '',
      regDate: json['REG_DATE'] ?? '',
      modDate: json['MOD_DATE'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NUM': num,
      'SUBJECT_CD': subjectCd,
      'TITLE': title,
      'ADDR': addr,
      'LA': la,
      'LO': lo,
      'TEL_NO': telNo,
      'URL': url,
      'OPERATING_TIME': operatingTime,
      'FREE_YN': freeYn,
      'ENTR_FEE': entrFee,
      'CONTENTS': contents,
      'SUBWAY': subway,
      'BUS': bus,
      'PARKING_INFO': parkingInfo,
      'REG_DATE': regDate,
      'MOD_DATE': modDate,
    };
  }
}

/// API 응답 모델
class NightSpotResponse {
  final int listTotalCount;
  final ResultCode result;
  final List<NightSpot> row;

  NightSpotResponse({
    required this.listTotalCount,
    required this.result,
    required this.row,
  });

  factory NightSpotResponse.fromJson(Map<String, dynamic> json) {
    final viewNightSpot = json['viewNightSpot'];
    return NightSpotResponse(
      listTotalCount: viewNightSpot['list_total_count'] ?? 0,
      result: ResultCode.fromJson(viewNightSpot['RESULT']),
      row: (viewNightSpot['row'] as List?)
              ?.map((item) => NightSpot.fromJson(item))
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
