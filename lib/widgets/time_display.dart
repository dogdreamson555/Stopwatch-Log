import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/timer_provider.dart';
import '../theme/app_typography.dart';

/// 时间显示组件：HH : MM : SS 格式，带中文标注
class TimeDisplay extends ConsumerWidget {
  final double scale;

  const TimeDisplay({super.key, this.scale = 1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final elapsed = ref.watch(timerProvider.select((s) => s.elapsed));
    final showSeconds = ref.watch(timerProvider.select((s) => s.showSeconds));

    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeBlock(hours.toString().padLeft(2, '0'), '小时', cs, scale),
            _Colon(cs: cs, scale: scale),
            _buildTimeBlock(
              minutes.toString().padLeft(2, '0'),
              '分钟',
              cs,
              scale,
            ),
            if (showSeconds) ...[
              _Colon(cs: cs, scale: scale),
              _buildTimeBlock(
                seconds.toString().padLeft(2, '0'),
                '秒',
                cs,
                scale,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTimeBlock(
    String value,
    String label,
    ColorScheme cs,
    double scale,
  ) {
    final labelSlotHeight = 25.0 * scale;

    return Column(
      children: [
        Text(
          value,
          style: AppTypography.display(
            fontSize: 56 * scale,
            fontWeight: FontWeight.w400,
            color: cs.onSurface,
            height: 1,
          ),
        ),
        if (label.isNotEmpty) ...[
          SizedBox(height: 6 * scale),
          Text(
            label,
            style: TextStyle(
              fontSize: 16 * scale,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ] else
          SizedBox(height: labelSlotHeight),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  final ColorScheme cs;
  final double scale;

  const _Colon({required this.cs, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5 * scale),
      child: SizedBox(
        width: 8 * scale,
        height: 56 * scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SeparatorDot(cs: cs, scale: scale),
            SizedBox(height: 13 * scale),
            _SeparatorDot(cs: cs, scale: scale),
          ],
        ),
      ),
    );
  }
}

class _SeparatorDot extends StatelessWidget {
  final ColorScheme cs;
  final double scale;

  const _SeparatorDot({required this.cs, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7 * scale,
      height: 7 * scale,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
    );
  }
}
