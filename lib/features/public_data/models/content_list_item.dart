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
  });

  factory ContentListItem.fromJson(Map<String, dynamic> json) {
    return ContentListItem(
      cid: json['cid'] ?? '',
      langCodeId: json['lang_code_id'] ?? '',
      comCtgrySn: json['com_ctgry_sn'] ?? '',
      cateDepth: List<String>.from(json['cate_depth'] ?? []),
      multiLangList: json['multi_lang_list'] ?? '',
      mainImg: json['main_img'] ?? '',
      postSj: json['post_sj'] ?? '',
      sumry: json['sumry'] ?? '',
      creatDtText: json['creat_dt_text'] ?? '',
      updtDtText: json['updt_dt_text'] ?? '',
    );
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
