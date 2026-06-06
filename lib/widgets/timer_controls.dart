import 'package:flutter/material.dart';

import '../providers/timer_provider.dart';

/// 计时器控制按钮组
class TimerControls extends StatelessWidget {
  final TimerStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const TimerControls({
    super.key,
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: switch (status) {
        TimerStatus.idle => [
          _buildButton(
            icon: Icons.play_arrow,
            color: cs.primary,
            onPressed: onStart,
          ),
          const SizedBox(width: 16),
          _buildButton(
            icon: Icons.refresh,
            color: cs.onSurface.withValues(alpha: 0.08),
            iconColor: cs.onSurface.withValues(alpha: 0.4),
            onPressed: null,
          ),
        ],
        TimerStatus.running => [
          _buildButton(
            icon: Icons.pause,
            color: cs.tertiary,
            onPressed: onPause,
          ),
          const SizedBox(width: 16),
          _buildButton(icon: Icons.stop, color: cs.error, onPressed: onStop),
        ],
        TimerStatus.paused => [
          _buildButton(
            icon: Icons.play_arrow,
            color: cs.primary,
            onPressed: onResume,
          ),
          const SizedBox(width: 16),
          _buildButton(icon: Icons.stop, color: cs.error, onPressed: onStop),
        ],
      },
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    Color? iconColor,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, size: 32, color: iconColor ?? Colors.white),
        ),
      ),
    );
  }
}
