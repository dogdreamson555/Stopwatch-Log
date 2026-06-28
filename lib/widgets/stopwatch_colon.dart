import 'package:flutter/material.dart';

/// A font-independent stopwatch colon that stays vertically centered while
/// its size changes.
class StopwatchColon extends StatelessWidget {
  final double width;
  final double height;
  final double baseSize;
  final double colonScale;
  final Color color;

  const StopwatchColon({
    super.key,
    required this.width,
    required this.height,
    required this.baseSize,
    required this.colonScale,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = baseSize * 0.11 * colonScale;
    final dotGap = baseSize * 0.19 * colonScale;

    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColonDot(size: dotSize, color: color),
            SizedBox(height: dotGap),
            _ColonDot(size: dotSize, color: color),
          ],
        ),
      ),
    );
  }
}

class _ColonDot extends StatelessWidget {
  final double size;
  final Color color;

  const _ColonDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
