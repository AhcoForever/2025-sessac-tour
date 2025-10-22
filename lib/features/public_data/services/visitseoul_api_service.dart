import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/content_info.dart';
import '../models/content_list_item.dart';

class VisitSeoulApiService{
  // api 키 입력 : VisitSeoul
  static String _apiKey = 'a067e1f9-09aa-4705-beb7-96f702a24fa9';
  static String _baseUrl = 'https://api-call.visitseoul.net';

  Future<ContentInfo?> getContentInfo(String cid) async {
    final url = '$_baseUrl/api/v1/contents/info';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'VISITSEOUL-API-KEY': _apiKey,
          'Content-Type': 'application/json;charset=UTF-8',
          'Accept': 'application/json;charset=UTF-8',
        },
        body: json.encode({
          'cid': cid,
        }),
      );

      print('상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // result_code가 200인지 확인
        if (jsonData['result_code'] == 200 && jsonData['data'] != null) {
          return ContentInfo.fromJson(jsonData['data']);
        } else {
          print('API 에러: ${jsonData['result_message']}');
          return null;
        }
      } else {
        print('HTTP 에러: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('API 호출 오류: $e');
      return null;
    }

  }
  Future<List<ContentInfo>> getMultipleContents(List<String> cidList)async{
    List<ContentInfo> results = [];
    for (String cid in cidList) {
      final content = await getContentInfo(cid);
      if (content != null) {
        results.add(content);
      }

      // API 호출 제한을 고려한 딜레이 (선택사항)
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return results;

  }


  Future<ContentListResponse?> getContentList({
    String? comCtgrySn,      // 카테고리 일련번호
    String? langCodeId,       // 언어 코드 (ko, en, ja, zh-CN, zh-TW)
    String? keyword,          // 검색 키워드
    String sortType = 'latest',  // 정렬 (latest, abc)
    int pageNo = 1,
  })async {
    final url = '$_baseUrl/api/v1/contents/list';

    // 요청 본문 구성
    Map<String, dynamic> requestBody = {
      'sort_type': sortType,
      'page_no': pageNo,
    };

    // 선택적 파라미터 추가
    if (comCtgrySn != null) requestBody['com_ctgry_sn'] = comCtgrySn;
    if (langCodeId != null) requestBody['lang_code_id'] = langCodeId;
    if (keyword != null) requestBody['keyword'] = keyword;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'VISITSEOUL-API-KEY': _apiKey,
          'Content-Type': 'application/json;charset=UTF-8',
          'Accept': 'application/json;charset=UTF-8',
        },
        body: json.encode(requestBody),
      );

      print('목록 조회 상태 코드: ${response.statusCode}');
      print('목록 조회 응답: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['result_code'] == 200) {
          return ContentListResponse.fromJson(jsonData);
        } else {
          print('API 에러: ${jsonData['result_message']}');
          return null;
        }
      } else {
        print('HTTP 에러: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('목록 조회 오류: $e');
      return null;
    }
  }
}