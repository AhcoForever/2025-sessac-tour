import 'package:flutter/material.dart';

/// 현재 위치로 이동하는 FloatingActionButton
class LocationFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const LocationFab({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: '내 위치로 이동',
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
    );
  }
}
