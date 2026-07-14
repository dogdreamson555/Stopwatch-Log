import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import 'stable_digit_text.dart';
import 'stopwatch_colon.dart';

/// 时间显示组件：HH : MM : SS 格式，带中文标注
class TimeDisplay extends ConsumerWidget {
  final double scale;

  const TimeDisplay({super.key, this.scale = 1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final elapsed = ref.watch(timerProvider.select((s) => s.elapsed));
    final showSeconds = ref.watch(timerProvider.select((s) => s.showSeconds));
    final displaySettings = ref.watch(stopwatchDisplaySettingsProvider);

    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeBlock(
                hours.toString().padLeft(2, '0'),
                context.l10n.hours,
                cs,
                scale,
                displaySettings,
              ),
              _Colon(cs: cs, scale: scale, displaySettings: displaySettings),
              _buildTimeBlock(
                minutes.toString().padLeft(2, '0'),
                context.l10n.minutes,
                cs,
                scale,
                displaySettings,
              ),
              if (showSeconds) ...[
                _Colon(cs: cs, scale: scale, displaySettings: displaySettings),
                _buildTimeBlock(
                  seconds.toString().padLeft(2, '0'),
                  context.l10n.seconds,
                  cs,
                  scale,
                  displaySettings,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBlock(
    String value,
    String label,
    ColorScheme cs,
    double scale,
    StopwatchSettings displaySettings,
  ) {
    final labelSlotHeight = 25.0 * scale;
    final fontPreset = displaySettings.effectiveFontPreset;
    final digitStyle = fontPreset.textStyle(
      customFontFamily: displaySettings.effectiveCustomFontFamily,
      fontSize: 56 * scale * displaySettings.digitScale,
      fontWeight: FontWeight.w400,
      color: cs.onSurface,
      height: 1,
    );

    return Column(
      children: [
        StableDigitText(value: value, style: digitStyle),
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
  final StopwatchSettings displaySettings;

  const _Colon({
    required this.cs,
    required this.scale,
    required this.displaySettings,
  });

  @override
  Widget build(BuildContext context) {
    final digitHeight = 56 * scale * displaySettings.digitScale;
    final colonWidth = 18 * scale * displaySettings.colonScale;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: displaySettings.separatorSpacing * scale,
      ),
      child: StopwatchColon(
        width: colonWidth,
        height: digitHeight,
        baseSize: 56 * scale,
        colonScale: displaySettings.colonScale,
        color: cs.onSurface.withValues(alpha: 0.72),
      ),
    );
  }
}
