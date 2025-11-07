import 'package:flutter/material.dart';
import '../../../public_data/models/night_spot.dart';
import '../../constants/map_constants.dart';

/// 야경명소 상세 정보를 표시하는 바텀 시트
class NightSpotBottomSheet extends StatelessWidget {
  /// 야경명소 정보
  final NightSpot spot;

  const NightSpotBottomSheet({
    super.key,
    required this.spot,
  });

  /// 바텀 시트를 표시하는 정적 메서드
  static Future<void> show(
    BuildContext context, {
    required NightSpot spot,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NightSpotBottomSheet(spot: spot),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * MapConstants.bottomSheetMaxHeightRatio,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🌙 ${spot.subjectCd}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 제목
                  Text(
                    spot.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 주소
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.addr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (spot.telNo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          spot.telNo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // 운영시간
                  if (spot.operatingTime.isNotEmpty) ...[
                    _buildInfoRow('운영시간', spot.operatingTime),
                    const SizedBox(height: 12),
                  ],
                  // 입장료
                  if (spot.entrFee.isNotEmpty) ...[
                    _buildInfoRow('입장료', spot.entrFee),
                    const SizedBox(height: 12),
                  ],
                  // 교통편
                  if (spot.subway.isNotEmpty) ...[
                    _buildInfoRow('🚇 지하철', spot.subway),
                    const SizedBox(height: 12),
                  ],
                  if (spot.bus.isNotEmpty) ...[
                    _buildInfoRow('🚌 버스', spot.bus),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
