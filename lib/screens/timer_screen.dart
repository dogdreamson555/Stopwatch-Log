import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/timer_provider.dart';
import '../providers/ui_provider.dart';
import '../services/window_service.dart';
import '../widgets/point_marker.dart';
import '../widgets/time_display.dart';
import '../widgets/timer_controls.dart';
import '../widgets/window_close_button.dart';
import 'history_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

/// 计时器主屏幕
class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final timeScale = _TimerLayoutMetrics.timeScaleFor(constraints);
            final topInset = _TimerLayoutMetrics.topInsetFor(constraints);

            return Column(
              children: [
                // 顶部拖拽栏（可拖拽窗口）
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) => windowManager.startDragging(),
                    child: Row(
                      children: [
                        // 悬浮模式按钮
                        WindowControlButton(
                          icon: Icons.picture_in_picture_alt,
                          tooltip: '切换到悬浮窗',
                          iconSize: 18,
                          onTap: () async {
                            final floatingMode = ref.read(
                              isFloatingModeProvider.notifier,
                            );
                            floatingMode.enter();
                            try {
                              await WindowService.enterFloatingMode();
                            } catch (_) {
                              floatingMode.exit();
                              rethrow;
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        // 历史记录按钮
                        WindowControlButton(
                          icon: Icons.history_rounded,
                          tooltip: '历史记录',
                          iconSize: 19,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 设置按钮
                        WindowControlButton(
                          icon: Icons.settings_outlined,
                          tooltip: '设置',
                          iconSize: 19,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox(height: 34)),
                        const WindowMinimizeButton(),
                        const SizedBox(width: 6),
                        const WindowMaximizeButton(),
                        const SizedBox(width: 6),
                        const WindowCloseButton(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _TimerLayoutMetrics.maxContentWidth,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: topInset),
                            // 时间显示区域
                            TimeDisplay(scale: timeScale),
                            SizedBox(height: 32 * timeScale),
                            // 控制按钮
                            TimerControls(
                              status: timerState.status,
                              onStart: () =>
                                  ref.read(timerProvider.notifier).start(),
                              onPause: () =>
                                  ref.read(timerProvider.notifier).pause(),
                              onResume: () =>
                                  ref.read(timerProvider.notifier).resume(),
                              onStop: () async {
                                final session = await ref
                                    .read(timerProvider.notifier)
                                    .stop();
                                if (!context.mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReviewScreen(session: session),
                                  ),
                                );
                              },
                              onReset: () =>
                                  ref.read(timerProvider.notifier).reset(),
                            ),
                            SizedBox(height: 20 * timeScale),
                            // 显示选项开关
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ToggleChip(
                                  label: '秒',
                                  value: timerState.showSeconds,
                                  onChanged: (_) => ref
                                      .read(timerProvider.notifier)
                                      .toggleSeconds(),
                                ),
                              ],
                            ),
                            SizedBox(height: 24 * timeScale),
                            // 打点区域（仅在计时活跃时显示）
                            if (timerState.isActive)
                              Expanded(
                                flex: 2,
                                child: PointMarker(
                                  onMark: (note) => ref
                                      .read(timerProvider.notifier)
                                      .markPoint(note),
                                  points: timerState.points,
                                ),
                              )
                            else
                              const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

abstract final class _TimerLayoutMetrics {
  static const maxContentWidth = 1500.0;

  static double timeScaleFor(BoxConstraints constraints) {
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : maxContentWidth;
    final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 820;
    final scale = math.min(width / 1180, height / 820);
    return scale.clamp(0.90, 1.48).toDouble();
  }

  static double topInsetFor(BoxConstraints constraints) {
    final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 820;
    return (height * 0.12).clamp(56.0, 150.0).toDouble();
  }
}

/// 显示选项开关小芯片
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: value ? cs.primary.withAlpha(30) : cs.onSurface.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? cs.primary.withAlpha(120)
                : cs.onSurface.withAlpha(25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.visibility : Icons.visibility_off,
              size: 14,
              color: value ? cs.primary : cs.onSurface.withAlpha(80),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: value ? cs.primary : cs.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
