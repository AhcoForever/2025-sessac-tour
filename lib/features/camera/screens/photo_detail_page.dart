import 'package:flutter/material.dart';
import '../models/photo_memory.dart';

/// 사진 상세 보기 페이지
class PhotoDetailPage extends StatelessWidget {
  final PhotoMemory memory;
  final VoidCallback? onDelete;

  const PhotoDetailPage({
    super.key,
    required this.memory,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                onDelete!();
                Navigator.pop(context);
              },
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // 사진
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  memory.photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 정보 카드
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 제목
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.blue[400],
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            memory.destinationName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 주소
                    _buildInfoRow(
                      icon: Icons.place,
                      label: '주소',
                      value: memory.destinationAddress,
                    ),

                    const SizedBox(height: 12),

                    // 날짜
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: '촬영일',
                      value: _formatDateTime(memory.timestamp),
                    ),

                    const SizedBox(height: 12),

                    // 좌표
                    _buildInfoRow(
                      icon: Icons.my_location,
                      label: '좌표',
                      value:
                          '${memory.latitude.toStringAsFixed(6)}, ${memory.longitude.toStringAsFixed(6)}',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.grey[400],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];

    return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday) '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
