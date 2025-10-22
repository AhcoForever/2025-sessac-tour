class ContentInfo {
  final String cid;
  final String langCodeId;
  final List<String> cateDepth;
  final String mainImg;
  final List<String> relateImg;
  final String postSj;           // 제목
  final String sumry;            // 요약
  final String schdulInfoBgnde;  // 시작일
  final String schdulInfoEndde;  // 종료일
  final List<String> tag;
  final ExtraInfo? extra;
  final TrafficInfo? traffic;
  final String postDesc;         // 상세 설명

  ContentInfo({
    required this.cid,
    required this.langCodeId,
    required this.cateDepth,
    required this.mainImg,
    required this.relateImg,
    required this.postSj,
    required this.sumry,
    required this.schdulInfoBgnde,
    required this.schdulInfoEndde,
    required this.tag,
    this.extra,
    this.traffic,
    required this.postDesc,
  });

  factory ContentInfo.fromJson(Map<String, dynamic> json) {
    return ContentInfo(
      cid: json['cid'] ?? '',
      langCodeId: json['lang_code_id'] ?? '',
      cateDepth: List<String>.from(json['cate_depth'] ?? []),
      mainImg: json['main_img'] ?? '',
      relateImg: List<String>.from(json['relate_img'] ?? []),
      postSj: json['post_sj'] ?? '',
      sumry: json['sumry'] ?? '',
      schdulInfoBgnde: json['schdul_info_bgnde'] ?? '',
      schdulInfoEndde: json['schdul_info_endde'] ?? '',
      tag: List<String>.from(json['tag'] ?? []),
      extra: json['extra'] != null ? ExtraInfo.fromJson(json['extra']) : null,
      traffic: json['traffic'] != null ? TrafficInfo.fromJson(json['traffic']) : null,
      postDesc: json['post_desc'] ?? '',
    );
  }
}

class ExtraInfo {
  final String? cmmnTelno;       // 전화번호
  final String? cmmnHmpgUrl;     // 홈페이지
  final String? cmmnUseTime;     // 이용시간
  final String? cmmnImportant;   // 중요정보
  final List<String>? disabledFacility;  // 장애인 시설
  final String? closedDays;      // 휴무일

  ExtraInfo({
    this.cmmnTelno,
    this.cmmnHmpgUrl,
    this.cmmnUseTime,
    this.cmmnImportant,
    this.disabledFacility,
    this.closedDays,
  });

  factory ExtraInfo.fromJson(Map<String, dynamic> json) {
    return ExtraInfo(
      cmmnTelno: json['cmmn_telno'],
      cmmnHmpgUrl: json['cmmn_hmpg_url'],
      cmmnUseTime: json['cmmn_use_time'],
      cmmnImportant: json['cmmn_important'],
      disabledFacility: json['disabled_facility'] != null
          ? List<String>.from(json['disabled_facility'])
          : null,
      closedDays: json['closed_days'],
    );
  }
}

class TrafficInfo {
  final String? adres;           // 구주소
  final String? newZipCode;      // 우편번호
  final String? newAdres;        // 신주소
  final String? mapPositionX;    // 경도
  final String? mapPositionY;    // 위도
  final String? subwayInfo;      // 지하철 정보

  TrafficInfo({
    this.adres,
    this.newZipCode,
    this.newAdres,
    this.mapPositionX,
    this.mapPositionY,
    this.subwayInfo,
  });

  factory TrafficInfo.fromJson(Map<String, dynamic> json) {
    return TrafficInfo(
      adres: json['adres'],
      newZipCode: json['new_zip_code'],
      newAdres: json['new_adres'],
      mapPositionX: json['map_position_x'],
      mapPositionY: json['map_position_y'],
      subwayInfo: json['subway_info'],
    );
  }
}