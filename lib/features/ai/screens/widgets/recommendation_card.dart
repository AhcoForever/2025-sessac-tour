import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/recommendation.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  /// 비용 표시 텍스트 생성 (무료가 아니면 "유료"로 표시)
  String _getDisplayCost() {
    if (recommendation.cost == null) return '';
    final cost = recommendation.cost!.toLowerCase();
    if (cost.contains('무료') || cost == '0' || cost == '0원') {
      return '무료';
    }
    return '유료';
  }

  /// 상세 정보 바텀시트 표시
  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  controller: scrollController,
                  children: [
                    // 핸들 바
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 카테고리 태그
                    _CategoryTag(category: recommendation.category),
                    const SizedBox(height: 16),

                    // 제목
                    Text(
                      recommendation.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // 설명
                    Text(
                      recommendation.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),

                    // 상세 정보
                    if (recommendation.distance != null)
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: '거리',
                        value: recommendation.distance!,
                      ),
                    if (recommendation.duration != null)
                      _DetailRow(
                        icon: Icons.access_time,
                        label: '소요 시간',
                        value: recommendation.duration!,
                      ),
                    if (recommendation.cost != null)
                      _DetailRow(
                        icon: Icons.credit_card,
                        label: '비용',
                        value: recommendation.cost!, // 실제 비용 표시
                      ),
                    if (recommendation.rating != null)
                      _DetailRow(
                        icon: Icons.star,
                        label: '평점',
                        value: '${recommendation.rating} / 5.0',
                      ),
                  ],
                ),
              ),
            ),
            // 하단 버튼들
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 저장하기 버튼
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: 저장하기 기능 구현
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text('저장하기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 루틴 선택하기 버튼
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                       context.goNamed("map");
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '루틴 선택하기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // 상세 정보 바텀시트 표시
          _showDetailBottomSheet(context);
          // 외부 onTap도 호출
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 태그와 북마크 아이콘
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CategoryTag(category: recommendation.category),
                  Icon(
                    Icons.bookmark_border,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 제목
              Text(
                recommendation.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // 설명
              Text(
                recommendation.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 16),

              // 메타 정보 (거리, 시간, 비용, 별점)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (recommendation.distance != null)
                    _MetaInfo(
                      icon: Icons.location_on_outlined,
                      text: recommendation.distance!,
                    ),
                  if (recommendation.duration != null)
                    _MetaInfo(
                      icon: Icons.access_time,
                      text: recommendation.duration!,
                    ),
                  if (recommendation.cost != null)
                    _MetaInfo(
                      icon: Icons.credit_card,
                      text: _getDisplayCost(), // 무료가 아니면 "유료"로 표시
                    ),
                  if (recommendation.rating != null)
                    _StarRating(rating: recommendation.rating!),
                ],
              ),
              const SizedBox(height: 16),

              // 하단 버튼
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '클릭해서 자세히 보기',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카테고리 태그 위젯
class _CategoryTag extends StatelessWidget {
  final String category;

  const _CategoryTag({required this.category});

  Color _getCategoryColor(BuildContext context) {
    // 카테고리별 색상 지정
    switch (category) {
      case '힐링형':
        return Colors.green.shade100;
      case '활력형':
        return Colors.orange.shade100;
      case '문화형':
        return Colors.blue.shade100;
      case '자연형':
        return Colors.teal.shade100;
      default:
        return Theme.of(context).colorScheme.secondaryContainer;
    }
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case '힐링형':
        return Icons.favorite_border;
      case '활력형':
        return Icons.bolt;
      case '문화형':
        return Icons.palette;
      case '자연형':
        return Icons.park;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 16,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// 메타 정보 위젯 (거리, 시간, 비용)
class _MetaInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// 별점 위젯
class _StarRating extends StatelessWidget {
  final double rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.shield_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            if (index < rating.floor()) {
              return const Icon(Icons.star, size: 16, color: Colors.amber);
            } else if (index < rating) {
              return const Icon(Icons.star_half, size: 16, color: Colors.amber);
            } else {
              return Icon(Icons.star_border,
                  size: 16, color: Colors.grey.shade400);
            }
          }),
        ),
      ],
    );
  }
}

/// 상세 정보 행 위젯 (바텀시트용)
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
