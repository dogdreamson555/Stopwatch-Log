import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/timer_point.dart';
import '../models/timer_session.dart';

// ============================================================
// 数据库 Provider（单例）
// ============================================================

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// ============================================================
// 会话归档 Notifier（AsyncNotifier 支持异步初始化）
// ============================================================

class SessionArchiveNotifier extends AsyncNotifier<List<TimerSession>> {
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<List<TimerSession>> build() async {
    final rows = await _db.allSessions();
    return Future.wait(rows.map(_rowToSession));
  }

  /// 添加一个新会话到归档并持久化
  Future<void> addSession(TimerSession session) async {
    // 先写数据库
    await _db.insertSession(
      SessionsCompanion(
        id: drift.Value(session.id),
        date: drift.Value(session.date),
        totalElapsedMs: drift.Value(session.totalElapsed.inMilliseconds),
        summary: drift.Value(session.summary),
      ),
    );
    if (session.points.isNotEmpty) {
      await _db.insertPoints(
        session.points
            .map(
              (p) => PointsCompanion(
                id: drift.Value(p.id),
                sessionId: drift.Value(session.id),
                elapsedAtMs: drift.Value(p.elapsedAt.inMilliseconds),
                createdAt: drift.Value(p.createdAt),
                note: drift.Value(p.note),
              ),
            )
            .toList(),
      );
    }
    // 更新内存状态
    state = AsyncData([session, ...state.value ?? []]);
  }

  /// 更新某个会话的自我总结
  Future<void> updateSummary(String sessionId, String summary) async {
    await _db.updateSummary(sessionId, summary);
    final list = state.value ?? [];
    state = AsyncData(
      list.map((s) {
        if (s.id == sessionId) return s.copyWith(summary: summary);
        return s;
      }).toList(),
    );
  }

  /// 删除某个会话
  Future<void> deleteSession(String sessionId) async {
    await _db.deleteSession(sessionId);
    final list = state.value ?? [];
    state = AsyncData(list.where((s) => s.id != sessionId).toList());
  }

  // ---- 内部转换 ----

  Future<TimerSession> _rowToSession(SessionRow row) async {
    final pointRows = await _db.pointsForSession(row.id);
    final points = pointRows
        .map(
          (p) => TimerPoint(
            id: p.id,
            elapsedAt: Duration(milliseconds: p.elapsedAtMs),
            createdAt: p.createdAt,
            note: p.note,
          ),
        )
        .toList();
    return TimerSession(
      id: row.id,
      date: row.date,
      totalElapsed: Duration(milliseconds: row.totalElapsedMs),
      points: points,
      summary: row.summary,
    );
  }
}

/// 全局会话归档 Provider
final sessionArchiveProvider =
    AsyncNotifierProvider<SessionArchiveNotifier, List<TimerSession>>(
      SessionArchiveNotifier.new,
    );
