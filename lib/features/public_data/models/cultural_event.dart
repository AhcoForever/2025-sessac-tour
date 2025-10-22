class CulturalEvent {
  final String title; // 행사명
  final String place; // 장소
  final String startDate; // 시작일
  final String endDate; // 종료일
  final String useFee; // 이용요금
  final String orgName; // 기관명
  final String guName; // 자치구
  final String codeName; // 분류 (공연/전시/축제 등)
  final String? thumbnail; // 썸네일 이미지 (없을 수도 있음)

  CulturalEvent({
    required this.title,
    required this.place,
    required this.startDate,
    required this.endDate,
    required this.useFee,
    required this.orgName,
    required this.guName,
    required this.codeName,
    this.thumbnail,
  });

  // JSON 에서 CulturalEvent 객체 생성
  factory CulturalEvent.fromJson(Map<String, dynamic> json) {
    return CulturalEvent(
      title: json['TITLE'] ?? '제목 없음',
      place: json['PLACE'] ?? '장소 미정',
      startDate: json['STRTDATE'] ?? '',
      endDate: json['END_DATE'] ?? '',
      useFee: json['USE_FEE'] ?? '정보 없음',
      orgName: json['ORG_NAME'] ?? '',
      guName: json['GUNAME'] ?? '',
      codeName: json['CODENAME'] ?? '',
      thumbnail: json['MAIN_IMG'],
    );
  }
}
