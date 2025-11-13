import 'package:flutter/material.dart';

/// 통계 카드 위젯
class StatCardWidget extends StatelessWidget {
  final List<Widget> children;
  final Gradient gradient;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const StatCardWidget({
    super.key,
    required this.children,
    required this.gradient,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _intersperse(
          children,
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  /// 리스트 사이에 구분자 삽입
  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty || items.length == 1) return items;

    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}
