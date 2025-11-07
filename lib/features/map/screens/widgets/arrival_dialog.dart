import 'package:flutter/material.dart';

/// 목적지 도착 시 표시되는 알림 다이얼로그
class ArrivalDialog extends StatelessWidget {
  /// 목적지 이름
  final String destinationName;

  /// 사진 찍기 버튼 클릭 콜백
  final VoidCallback onTakePhoto;

  const ArrivalDialog({
    super.key,
    required this.destinationName,
    required this.onTakePhoto,
  });

  /// 다이얼로그를 표시하는 정적 메서드
  static Future<void> show(
    BuildContext context, {
    required String destinationName,
    required VoidCallback onTakePhoto,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ArrivalDialog(
        destinationName: destinationName,
        onTakePhoto: onTakePhoto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.celebration, color: Colors.amber[700], size: 28),
          const SizedBox(width: 8),
          const Text('도착했어요! 🎉'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$destinationName에 도착하셨습니다!',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            '5분 이내에 인증샷을 찍어주세요.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '사진은 마이페이지 보관함에 저장됩니다.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('나중에'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onTakePhoto();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 20),
              SizedBox(width: 6),
              Text('사진 찍기'),
            ],
          ),
        ),
      ],
    );
  }
}
