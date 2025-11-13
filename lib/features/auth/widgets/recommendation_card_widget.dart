import 'package:flutter/material.dart';
import '../../ai/models/user_chat_profile.dart';
import '../../../core/utils/date_formatter.dart';

/// 추천 카드 위젯
class RecommendationCardWidget extends StatelessWidget {
  final RecommendationHistory recommendation;

  const RecommendationCardWidget({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(recommendation.category)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(recommendation.category),
                    color: _getCategoryColor(recommendation.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(recommendation.category)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recommendation.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(recommendation.category),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (recommendation.description != null) ...[
              const SizedBox(height: 12),
              Text(
                recommendation.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.formatDate(recommendation.timestamp),
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
    );
  }

  Color _getCategoryColor(String category) {
    if (category.contains('힐링')) return Colors.green;
    if (category.contains('활력')) return Colors.orange;
    if (category.contains('문화')) return Colors.purple;
    if (category.contains('야경')) return Colors.indigo;
    if (category.contains('공원')) return Colors.teal;
    return Colors.blue;
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('힐링')) return Icons.spa;
    if (category.contains('활력')) return Icons.local_fire_department;
    if (category.contains('문화')) return Icons.palette;
    if (category.contains('야경')) return Icons.nights_stay;
    if (category.contains('공원')) return Icons.park;
    return Icons.place;
  }
}
