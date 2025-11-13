import 'package:flutter/material.dart';

/// 통계 아이템 위젯
class StatItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? textColor;

  const StatItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.white;
    final effectiveTextColor = textColor ?? Colors.white;

    return Column(
      children: [
        Icon(icon, color: effectiveIconColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: effectiveTextColor.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
