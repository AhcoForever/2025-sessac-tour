import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 둥실둥실 떠다니는 애니메이션 마커
class FloatingMarker extends StatefulWidget {
  final String imagePath;
  final double size;
  final VoidCallback? onTap;

  const FloatingMarker({
    super.key,
    required this.imagePath,
    this.size = 120,
    this.onTap,
  });

  @override
  State<FloatingMarker> createState() => _FloatingMarkerState();
}

class _FloatingMarkerState extends State<FloatingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          // 사인파를 사용해서 부드러운 위아래 움직임
          final offset = math.sin(_floatingAnimation.value * 2 * math.pi) * 8;

          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
        child: Image.asset(
          widget.imagePath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
