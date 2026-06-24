import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/timer_point.dart';
import '../models/timer_session.dart';
import '../providers/session_archive_provider.dart';
import '../theme/app_typography.dart';

/// 复盘归档页面 —— 结束计时后自动跳转至此
class ReviewScreen extends ConsumerStatefulWidget {
  final TimerSession session;

  const ReviewScreen({super.key, required this.session});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.session.summary);
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  void _saveSummary() async {
    await ref
        .read(sessionArchiveProvider.notifier)
        .updateSummary(widget.session.id, _summaryController.text.trim());
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.summarySaved,
          style: TextStyle(color: cs.onPrimary),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: cs.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final dateStr =
        '${material.formatFullDate(s.date)}  '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(s.date), alwaysUse24HourFormat: true)}';
    final totalStr = _formatDuration(s.totalElapsed);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewArchive),
        actions: [
          TextButton.icon(
            onPressed: _saveSummary,
            icon: const Icon(Icons.save, size: 18),
            label: Text(l10n.save),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 日期 ──
            _buildInfoCard(
              icon: Icons.calendar_today,
              label: l10n.date,
              value: dateStr,
            ),
            const SizedBox(height: 12),

            // ── 净总时长 ──
            _buildInfoCard(
              icon: Icons.timer,
              label: l10n.netDuration,
              value: totalStr,
              highlight: true,
            ),
            const SizedBox(height: 24),

            // ── 打点流 ──
            _buildSectionTitle(l10n.pointStream, Icons.flag_outlined),
            const SizedBox(height: 8),
            if (s.points.isEmpty)
              _buildEmptyHint(l10n.noPointsThisSession)
            else
              ...s.points.asMap().entries.map(
                (e) => _buildPointTile(e.key + 1, e.value),
              ),

            const SizedBox(height: 24),

            // ── 自我总结 ──
            _buildSectionTitle(l10n.selfSummary, Icons.edit_note),
            const SizedBox(height: 8),
            TextField(
              controller: _summaryController,
              maxLines: 5,
              style: TextStyle(color: cs.onSurface, fontSize: 15),
              decoration: InputDecoration(
                hintText: l10n.summaryHint,
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── 信息卡片 ──
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: highlight
                ? AppTypography.display(
                    color: cs.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  )
                : TextStyle(
                    color: highlight ? cs.primary : cs.onSurface,
                    fontSize: highlight ? 18 : 14,
                    fontWeight: FontWeight.w400,
                  ),
          ),
        ],
      ),
    );
  }

  // ── 区块标题 ──
  Widget _buildSectionTitle(String title, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.onSurface.withValues(alpha: 0.4), size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.4),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── 空提示 ──
  Widget _buildEmptyHint(String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.3),
          fontSize: 13,
        ),
      ),
    );
  }

  // ── 单条打点记录 ──
  Widget _buildPointTile(int index, TimerPoint point) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = _formatPointTime(point.elapsedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: cs.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              timeStr,
              style: AppTypography.display(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 备注
          Expanded(
            child: Text(
              point.note,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h : $m : $s';
  }

  String _formatPointTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
