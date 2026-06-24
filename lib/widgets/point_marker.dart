import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/timer_point.dart';
import '../theme/app_typography.dart';

/// 打点备注组件：快速输入备注并打点
class PointMarker extends StatefulWidget {
  final void Function(String note) onMark;
  final List<TimerPoint> points;

  const PointMarker({super.key, required this.onMark, required this.points});

  @override
  State<PointMarker> createState() => _PointMarkerState();
}

class _PointMarkerState extends State<PointMarker> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  String? _emphasizedPointId;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onMark(text);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  void didUpdateWidget(PointMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points.length > oldWidget.points.length) {
      final newestPoint = widget.points.last;
      _emphasizedPointId = newestPoint.id;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      });

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted || _emphasizedPointId != newestPoint.id) return;
        setState(() => _emphasizedPointId = null);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isHeightBounded = constraints.maxHeight.isFinite;
        final pointsList = _buildPointsList(cs);

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: TextStyle(color: cs.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: context.l10n.pointNoteHint,
                      hintStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                      filled: true,
                      fillColor: cs.onSurface.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submit,
                  icon: Icon(Icons.bookmark_add, color: cs.primary),
                  tooltip: context.l10n.markPoint,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.points.isNotEmpty)
              if (isHeightBounded)
                Expanded(child: pointsList)
              else
                SizedBox(height: 220, child: pointsList),
          ],
        );
      },
    );
  }

  Widget _buildPointsList(ColorScheme cs) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: widget.points.length > 5,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: widget.points.length,
        itemBuilder: (_, i) {
          final p = widget.points[widget.points.length - 1 - i];
          final ts = _formatPointTime(p.elapsedAt);
          final isEmphasized = p.id == _emphasizedPointId;

          return TweenAnimationBuilder<double>(
            key: ValueKey(p.id),
            tween: Tween(begin: isEmphasized ? 1 : 0, end: 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -6 * value),
                child: Opacity(opacity: 1 - value * 0.2, child: child),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isEmphasized
                    ? cs.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ts,
                      style: AppTypography.display(
                        color: cs.primary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.note,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPointTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
