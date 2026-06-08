import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/ui_provider.dart';
import '../services/window_service.dart';
import 'window_close_button.dart';

/// 悬浮模式下的紧凑计时器 UI
class FloatingTimer extends ConsumerWidget {
  const FloatingTimer({super.key});

  Future<void> _exitFloating(WidgetRef ref) async {
    await WindowService.exitFloatingMode();
    ref.read(isFloatingModeProvider.notifier).exit();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final displaySettings = ref.watch(stopwatchDisplaySettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : _FloatingMetrics.compactWidth;
            final height = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : _FloatingMetrics.compactHeight;
            final scale = math
                .min(
                  width / _FloatingMetrics.compactWidth,
                  height / _FloatingMetrics.compactHeight,
                )
                .clamp(1.0, _FloatingMetrics.maxScale)
                .toDouble();

            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                children: [
                  _FloatingTitleBar(onExit: () => _exitFloating(ref)),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FloatingTimeDisplay(
                            elapsed: timerState.elapsed,
                            showSeconds: timerState.showSeconds,
                            scale: scale,
                            displaySettings: displaySettings,
                          ),
                          SizedBox(height: 10 * scale),
                          _FloatingActions(
                            status: timerState.status,
                            scale: scale,
                            onStart: () =>
                                ref.read(timerProvider.notifier).start(),
                            onPause: () =>
                                ref.read(timerProvider.notifier).pause(),
                            onMark: () =>
                                ref.read(timerProvider.notifier).markPoint(''),
                            onResume: () =>
                                ref.read(timerProvider.notifier).resume(),
                            onStop: () async {
                              await ref.read(timerProvider.notifier).stop();
                              await _exitFloating(ref);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

abstract final class _FloatingMetrics {
  static const compactWidth = 208.0;
  static const compactHeight = 174.0;
  static const maxScale = 1.45;
  static const compactTimeScaleFactor = 0.90;

  static double timeScaleFor(double scale) {
    final progress = ((scale - 1) / (maxScale - 1)).clamp(0.0, 1.0);
    final factor =
        compactTimeScaleFactor + (1 - compactTimeScaleFactor) * progress;
    return scale * factor;
  }
}

class _FloatingTitleBar extends StatelessWidget {
  final VoidCallback onExit;

  const _FloatingTitleBar({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          WindowControlButton(
            icon: Icons.open_in_full_rounded,
            tooltip: '退出悬浮窗',
            size: 28,
            iconSize: 15,
            compact: true,
            onTap: onExit,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => windowManager.startDragging(),
              child: const MouseRegion(
                cursor: SystemMouseCursors.move,
                child: SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const WindowMinimizeButton(size: 28, iconSize: 15, compact: true),
          const SizedBox(width: 6),
          const WindowCloseButton(size: 28, iconSize: 16, compact: true),
        ],
      ),
    );
  }
}

class _FloatingTimeDisplay extends StatelessWidget {
  final Duration elapsed;
  final bool showSeconds;
  final double scale;
  final StopwatchSettings displaySettings;

  const _FloatingTimeDisplay({
    required this.elapsed,
    required this.showSeconds,
    required this.scale,
    required this.displaySettings,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    final parts = [
      _TimePart(hours.toString().padLeft(2, '0'), '小时'),
      _TimePart(minutes.toString().padLeft(2, '0'), '分钟'),
      if (showSeconds) _TimePart(seconds.toString().padLeft(2, '0'), '秒'),
    ];
    final timeScale = _FloatingMetrics.timeScaleFor(scale);
    final fontSize =
        (showSeconds ? 34.0 : 48.0) * timeScale * displaySettings.digitScale;
    final colonFontSize =
        (showSeconds ? 34.0 : 48.0) * timeScale * displaySettings.colonScale;
    final blockWidth =
        (showSeconds ? 49.0 : 66.0) * scale * displaySettings.digitScale;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            _FloatingTimeBlock(
              value: parts[i].value,
              label: parts[i].label,
              width: blockWidth,
              fontSize: fontSize,
              scale: scale,
              displaySettings: displaySettings,
            ),
            if (i < parts.length - 1)
              _FloatingSeparator(
                height: fontSize > colonFontSize ? fontSize : colonFontSize,
                fontSize: colonFontSize,
                scale: timeScale,
                cs: cs,
                displaySettings: displaySettings,
              ),
          ],
        ],
      ),
    );
  }
}

class _FloatingTimeBlock extends StatelessWidget {
  final String value;
  final String label;
  final double width;
  final double fontSize;
  final double scale;
  final StopwatchSettings displaySettings;

  const _FloatingTimeBlock({
    required this.value,
    required this.label,
    required this.width,
    required this.fontSize,
    required this.scale,
    required this.displaySettings,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fontPreset = displaySettings.effectiveFontPreset;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: fontSize,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: fontPreset.textStyle(
                  customFontFamily: displaySettings.effectiveCustomFontFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurface.withValues(alpha: 0.74),
                  height: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13 * scale,
              height: 1,
              color: cs.onSurface.withValues(alpha: 0.36),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingSeparator extends StatelessWidget {
  final double height;
  final double fontSize;
  final double scale;
  final ColorScheme cs;
  final StopwatchSettings displaySettings;

  const _FloatingSeparator({
    required this.height,
    required this.fontSize,
    required this.scale,
    required this.cs,
    required this.displaySettings,
  });

  @override
  Widget build(BuildContext context) {
    final fontPreset = displaySettings.effectiveFontPreset;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: displaySettings.separatorSpacing * scale,
      ),
      child: SizedBox(
        width: 10 * scale * displaySettings.colonScale,
        height: height,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            ':',
            style: fontPreset.textStyle(
              customFontFamily: displaySettings.effectiveCustomFontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: cs.onSurface.withValues(alpha: 0.52),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingActions extends StatelessWidget {
  final TimerStatus status;
  final double scale;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onMark;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _FloatingActions({
    required this.status,
    required this.scale,
    required this.onStart,
    required this.onPause,
    required this.onMark,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final buttonSize = 40 * scale;
    final primaryIconSize = 19 * scale;
    final secondaryIconSize = 18 * scale;
    final buttonGap = 16 * scale;
    final children = switch (status) {
      TimerStatus.idle => [
        _RoundActionButton(
          icon: Icons.play_arrow_rounded,
          tooltip: '开始',
          color: cs.primary,
          size: buttonSize,
          iconSize: primaryIconSize,
          onTap: onStart,
        ),
      ],
      TimerStatus.running => [
        _RoundActionButton(
          icon: Icons.pause_rounded,
          tooltip: '暂停',
          color: cs.tertiary,
          size: buttonSize,
          iconSize: primaryIconSize,
          onTap: onPause,
        ),
        SizedBox(width: buttonGap),
        _RoundActionButton(
          icon: Icons.bookmark_add_rounded,
          tooltip: '打点',
          color: cs.secondary,
          emphasized: false,
          size: buttonSize,
          iconSize: secondaryIconSize,
          onTap: onMark,
        ),
      ],
      TimerStatus.paused => [
        _RoundActionButton(
          icon: Icons.play_arrow_rounded,
          tooltip: '继续',
          color: cs.primary,
          size: buttonSize,
          iconSize: primaryIconSize,
          onTap: onResume,
        ),
        SizedBox(width: buttonGap),
        _RoundActionButton(
          icon: Icons.stop_rounded,
          tooltip: '结束',
          color: cs.error,
          size: buttonSize,
          iconSize: primaryIconSize,
          onTap: onStop,
        ),
      ],
    };

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final bool emphasized;
  final double size;
  final double iconSize;

  const _RoundActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.emphasized = true,
    this.size = 60,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = emphasized ? color : color.withValues(alpha: 0.10);
    final foregroundColor = emphasized ? Colors.white : color;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Semantics(
        button: true,
        label: tooltip,
        child: SizedBox.square(
          dimension: size,
          child: Material(
            color: backgroundColor,
            shape: CircleBorder(
              side: emphasized
                  ? BorderSide.none
                  : BorderSide(color: color.withValues(alpha: 0.22)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              hoverColor: (emphasized ? Colors.white : color).withValues(
                alpha: 0.08,
              ),
              splashColor: (emphasized ? Colors.white : color).withValues(
                alpha: 0.12,
              ),
              onTap: onTap,
              child: Icon(icon, size: iconSize, color: foregroundColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePart {
  final String value;
  final String label;

  const _TimePart(this.value, this.label);
}
