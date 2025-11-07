import 'package:flutter/material.dart';
import '../../constants/map_constants.dart';

/// 목적지까지의 거리를 표시하는 위젯
class DistanceIndicatorWidget extends StatelessWidget {
  /// 목적지 이름
  final String destinationName;

  /// 목적지까지의 거리 (미터 단위)
  final double distance;

  const DistanceIndicatorWidget({
    super.key,
    required this.destinationName,
    required this.distance,
  });

  /// 거리를 사람이 읽기 쉬운 형식으로 변환
  String _formatDistance() {
    if (distance < 1000) {
      return '${distance.toInt()}m';
    }
    return '${(distance / 1000).toStringAsFixed(1)}km';
  }

  /// 도착 여부
  bool get _hasArrived => distance <= MapConstants.arrivalThreshold;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.navigation,
                  color: Colors.green[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destinationName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDistance(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _hasArrived
                                ? Colors.green[700]
                                : Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _hasArrived ? '도착!' : '남음',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_hasArrived)
                Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
