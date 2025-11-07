import 'package:flutter/material.dart';

import '../../../public_data/models/content_info.dart';

/// 관광지 상세 정보를 표시하는 바텀 시트
class TouristSpotBottomSheet extends StatelessWidget {
  final ContentInfo spot;
  final VoidCallback? onSetDestination;

  const TouristSpotBottomSheet({
    super.key,
    required this.spot,
    this.onSetDestination,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // 드래그 핸들
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 스크롤 가능한 컨텐츠
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // 썸네일 이미지
                      if (spot.mainImg.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            spot.mainImg,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 제목
                      Text(
                        spot.postSj,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 카테고리
                      if (spot.cateDepth.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  spot.cateDepth.join(' > '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // 주소
                      if (spot.traffic?.newAdres != null ||
                          spot.traffic?.adres != null)
                        _buildInfoRow(
                          icon: Icons.location_on,
                          iconColor: Colors.red,
                          title: '주소',
                          content:
                              spot.traffic?.newAdres ?? spot.traffic?.adres ?? '',
                        ),

                      // 전화번호
                      if (spot.extra?.cmmnTelno != null &&
                          spot.extra!.cmmnTelno!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.phone,
                          iconColor: Colors.green,
                          title: '전화번호',
                          content: spot.extra!.cmmnTelno!,
                        ),

                      // 홈페이지
                      if (spot.extra?.cmmnHmpgUrl != null &&
                          spot.extra!.cmmnHmpgUrl!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.language,
                          iconColor: Colors.purple,
                          title: '홈페이지',
                          content: spot.extra!.cmmnHmpgUrl!,
                        ),

                      // 운영시간
                      if (spot.extra?.cmmnUseTime != null &&
                          spot.extra!.cmmnUseTime!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.access_time,
                          iconColor: Colors.orange,
                          title: '운영시간',
                          content: spot.extra!.cmmnUseTime!,
                        ),

                      // 휴무일
                      if (spot.extra?.closedDays != null &&
                          spot.extra!.closedDays!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.event_busy,
                          iconColor: Colors.grey,
                          title: '휴무일',
                          content: spot.extra!.closedDays!,
                        ),

                      // 지하철 정보
                      if (spot.traffic?.subwayInfo != null &&
                          spot.traffic!.subwayInfo!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.subway,
                          iconColor: Colors.blue,
                          title: '지하철',
                          content: spot.traffic!.subwayInfo!,
                        ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // 요약
                      if (spot.sumry.isNotEmpty) ...[
                        const Text(
                          '소개',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          spot.sumry,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 상세 설명
                      if (spot.postDesc.isNotEmpty) ...[
                        const Text(
                          '상세 정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cleanHtmlText(spot.postDesc),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ],

                          const SizedBox(height: 80), // 하단 여백
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 목적지 설정 버튼
              if (onSetDestination != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onSetDestination!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '출발하기',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: onTap != null ? Colors.blue : Colors.black87,
                        decoration:
                            onTap != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// HTML 태그 제거
  String _cleanHtmlText(String htmlText) {
    return htmlText
        // style 태그와 그 내용 제거
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '')
        // script 태그와 그 내용 제거
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        // 모든 HTML 태그 제거
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // HTML 엔터티 변환
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        // 여러 공백을 하나로
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
