import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/timer_session.dart';
import '../providers/session_archive_provider.dart';
import '../theme/app_typography.dart';
import 'review_screen.dart';

/// 历史记录列表 —— 可展开查看总结，点击进入复盘详情
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionArchiveProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('加载失败: $err', style: TextStyle(color: cs.error)),
        ),
        data: (sessions) => sessions.isEmpty
            ? _buildEmptyState(cs)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: sessions.length,
                itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
              ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有计时记录',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '开始第一次专注计时吧',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.2),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条会话卡片 —— 可展开
class _SessionCard extends ConsumerStatefulWidget {
  final TimerSession session;
  const _SessionCard({required this.session});

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('M月d日  HH:mm').format(s.date);
    final durationStr = _fmtDuration(s.totalElapsed);

    return Dismissible(
      key: Key(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      onDismissed: (_) async {
        await ref.read(sessionArchiveProvider.notifier).deleteSession(s.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), duration: Duration(seconds: 2)),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ReviewScreen(session: s)));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 56, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (s.points.isNotEmpty) ...[
                          Icon(
                            Icons.flag_outlined,
                            size: 12,
                            color: cs.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${s.points.length}',
                            style: TextStyle(
                              color: cs.primary.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          durationStr,
                          style: AppTypography.display(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: _buildExpandedContent(s, cs),
                      crossFadeState: _expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 56,
                child: Tooltip(
                  message: _expanded ? '收起摘要' : '展开摘要',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleExpanded,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(TimerSession s, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分隔线
          Divider(color: cs.onSurface.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 8),

          // 总结
          if (s.summary.isNotEmpty) ...[
            Text(
              '📝 总结',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.summary,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ] else ...[
            Text(
              '（未填写总结）',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.25),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // 打点流摘要
          if (s.points.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '🚩 打点 (${s.points.length})',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            ...s.points
                .take(3)
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text(
                          _fmtPointTime(p.elapsedAt),
                          style: AppTypography.display(
                            color: cs.primary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.note,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (s.points.length > 3)
              Text(
                '... 还有 ${s.points.length - 3} 条',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.25),
                  fontSize: 11,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fmtPointTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
