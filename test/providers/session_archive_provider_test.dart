import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/database/database.dart';
import 'package:stopwatch_log/models/timer_point.dart';
import 'package:stopwatch_log/models/timer_session.dart';
import 'package:stopwatch_log/providers/session_archive_provider.dart';

ProviderContainer _createContainer(AppDatabase db) {
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}

void main() {
  test('adds sessions with points and loads them newest first', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = _createContainer(db);
    final notifier = container.read(sessionArchiveProvider.notifier);

    expect(await container.read(sessionArchiveProvider.future), isEmpty);

    final older = TimerSession(
      id: 'older',
      date: DateTime(2026, 6, 5),
      totalElapsed: const Duration(minutes: 3),
    );
    final newer = TimerSession(
      id: 'newer',
      date: DateTime(2026, 6, 6),
      totalElapsed: const Duration(minutes: 5),
      points: [
        TimerPoint(
          id: 'point-1',
          elapsedAt: const Duration(minutes: 2),
          createdAt: DateTime(2026, 6, 6, 0, 2),
          note: 'important',
        ),
      ],
    );

    await notifier.addSession(older);
    await notifier.addSession(newer);

    final state = container.read(sessionArchiveProvider).value!;
    expect(state.map((s) => s.id), ['newer', 'older']);

    final rows = await db.allSessions();
    expect(rows.map((r) => r.id), ['newer', 'older']);

    final points = await db.pointsForSession('newer');
    expect(points, hasLength(1));
    expect(points.single.note, 'important');
    expect(
      points.single.elapsedAtMs,
      const Duration(minutes: 2).inMilliseconds,
    );
  });

  test('updates summaries and deletes sessions with their points', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = _createContainer(db);
    final notifier = container.read(sessionArchiveProvider.notifier);

    await container.read(sessionArchiveProvider.future);
    await notifier.addSession(
      TimerSession(
        id: 'session-1',
        date: DateTime(2026, 6, 6),
        totalElapsed: const Duration(minutes: 10),
        points: [
          TimerPoint(
            id: 'point-1',
            elapsedAt: const Duration(minutes: 4),
            createdAt: DateTime(2026, 6, 6, 0, 4),
          ),
        ],
      ),
    );

    await notifier.updateSummary('session-1', 'reviewed');
    expect(
      container.read(sessionArchiveProvider).value!.single.summary,
      'reviewed',
    );
    expect((await db.allSessions()).single.summary, 'reviewed');

    await notifier.deleteSession('session-1');
    expect(container.read(sessionArchiveProvider).value, isEmpty);
    expect(await db.pointsForSession('session-1'), isEmpty);
    expect(await db.allSessions(), isEmpty);
  });
}
