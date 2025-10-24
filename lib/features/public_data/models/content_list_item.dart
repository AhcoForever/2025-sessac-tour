class ContentListItem {
  final String cid;
  final String langCodeId;
  final String comCtgrySn;
  final List<String> cateDepth;
  final String multiLangList;
  final String mainImg;
  final String postSj; // 제목
  final String sumry; // 요약
  final String creatDtText; // 생성일
  final String updtDtText; // 수정일
  final String schdulInfoBgnde; // 시작일
  final String schdulInfoEndde; // 종료일

  ContentListItem({
    required this.cid,
    required this.langCodeId,
    required this.comCtgrySn,
    required this.cateDepth,
    required this.multiLangList,
    required this.mainImg,
    required this.postSj,
    required this.sumry,
    required this.creatDtText,
    required this.updtDtText,
    required this.schdulInfoBgnde,
    required this.schdulInfoEndde,
  });

  factory ContentListItem.fromJson(Map<String, dynamic> json) {
    // cate_depth 파싱: String 또는 List 모두 처리
    List<String> parseCateDepth(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        // String인 경우 '>' 기준으로 split
        return value.isEmpty ? [] : value.split('>').map((e) => e.trim()).toList();
      }
      return [];
    }

    return ContentListItem(
      cid: json['cid'] ?? '',
      langCodeId: json['lang_code_id'] ?? '',
      comCtgrySn: json['com_ctgry_sn'] ?? '',
      cateDepth: parseCateDepth(json['cate_depth']),
      multiLangList: json['multi_lang_list'] ?? '',
      mainImg: json['main_img'] ?? '',
      postSj: json['post_sj'] ?? '',
      sumry: json['sumry'] ?? '',
      creatDtText: json['creat_dt_text'] ?? '',
      updtDtText: json['updt_dt_text'] ?? '',
      schdulInfoBgnde: json['schdul_info_bgnde'] ?? '',
      schdulInfoEndde: json['schdul_info_endde'] ?? '',
    );
  }

  // 현재 진행 중인지 확인
  bool isOngoing() {
    if (schdulInfoBgnde.isEmpty || schdulInfoEndde.isEmpty) {
      return true; // 일정 정보가 없으면 항상 표시
    }

    try {
      final now = DateTime.now();
      final startDate = _parseDate(schdulInfoBgnde);
      final endDate = _parseDate(schdulInfoEndde);

      if (startDate == null || endDate == null) {
        return true; // 파싱 실패 시 항상 표시
      }

      // 현재 날짜가 시작일~종료일 사이인지 확인
      return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
          now.isBefore(endDate.add(const Duration(days: 1)));
    } catch (e) {
      return true; // 오류 발생 시 항상 표시
    }
  }

  // 날짜 파싱 헬퍼 함수 (여러 형식 지원)
  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    try {
      // "YYYY-MM-DD" 형식
      if (dateString.contains('-')) {
        return DateTime.parse(dateString);
      }
      // "YYYY.MM.DD" 형식
      if (dateString.contains('.')) {
        final parts = dateString.split('.');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
      // "YYYYMMDD" 형식
      if (dateString.length == 8) {
        return DateTime(
          int.parse(dateString.substring(0, 4)),
          int.parse(dateString.substring(4, 6)),
          int.parse(dateString.substring(6, 8)),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class ContentListResponse {
  final List<ContentListItem> data;
  final PagingInfo paging;
  final int resultCode;
  final String resultMessage;

  ContentListResponse({
    required this.data,
    required this.paging,
    required this.resultCode,
    required this.resultMessage,
  });

  factory ContentListResponse.fromJson(Map<String, dynamic> json) {
    return ContentListResponse(
      data: (json['data'] as List)
          .map((item) => ContentListItem.fromJson(item))
          .toList(),
      paging: PagingInfo.fromJson(json['paging']),
      resultCode: json['result_code'] ?? 0,
      resultMessage: json['result_message'] ?? '',
    );
  }
}

class PagingInfo {
  final int pageNo;
  final int pageSize;
  final int totalCount;

  PagingInfo({
    required this.pageNo,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagingInfo.fromJson(Map<String, dynamic> json) {
    return PagingInfo(
      pageNo: json['page_no'] ?? 1,
      pageSize: json['page_size'] ?? 50,
      totalCount: json['total_count'] ?? 0,
    );
  }

  // 전체 페이지 수 계산
  int get totalPages => (totalCount / pageSize).ceil();

  // 다음 페이지가 있는지 확인
  bool get hasNextPage => pageNo < totalPages;
}
