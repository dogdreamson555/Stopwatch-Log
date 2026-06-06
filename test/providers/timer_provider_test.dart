import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/database/database.dart';
import 'package:stopwatch_log/models/timer_point.dart';
import 'package:stopwatch_log/providers/session_archive_provider.dart';
import 'package:stopwatch_log/providers/timer_provider.dart';

ProviderContainer _createContainer(AppDatabase db) {
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await db.close();
  });
  return container;
}

Future<void> _waitUntil(
  bool Function() condition, {
  String reason = 'condition was not met',
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail(reason);
}

void main() {
  test('restores a paused draft from persistent storage', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final draft = TimerState(
      status: TimerStatus.paused,
      elapsed: const Duration(minutes: 1, seconds: 23),
      sessionId: 'draft-session',
      sessionStartTime: DateTime(2026, 6, 6, 9),
      showSeconds: false,
      showHundredths: false,
      points: [
        TimerPoint(
          id: 'point-1',
          elapsedAt: const Duration(seconds: 42),
          createdAt: DateTime(2026, 6, 6, 9, 0, 42),
          note: 'restored point',
        ),
      ],
    );
    await db.saveCurrentTimerState(
      jsonEncode(draft.toDraftJson(DateTime.now())),
    );

    final container = _createContainer(db);
    expect(container.read(timerProvider).isIdle, isTrue);

    await _waitUntil(
      () => container.read(timerProvider).sessionId == 'draft-session',
      reason: 'timer draft was not restored',
    );

    final restored = container.read(timerProvider);
    expect(restored.status, TimerStatus.paused);
    expect(restored.elapsed, const Duration(minutes: 1, seconds: 23));
    expect(restored.showSeconds, isFalse);
    expect(restored.showHundredths, isFalse);
    expect(restored.points.single.note, 'restored point');
  });

  test('stop archives the active timer and clears the draft', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = _createContainer(db);
    final timer = container.read(timerProvider.notifier);

    await container.read(sessionArchiveProvider.future);
    timer.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    timer.markPoint('first point');
    timer.pause();
    await timer.persistNow();

    expect(await db.loadCurrentTimerState(), isNotNull);

    final archived = await timer.stop();

    expect(container.read(timerProvider).isIdle, isTrue);
    expect(await db.loadCurrentTimerState(), isNull);
    expect(archived.points.single.note, 'first point');

    final sessions = await container.read(sessionArchiveProvider.future);
    expect(sessions, hasLength(1));
    expect(sessions.single.id, archived.id);
    expect(sessions.single.points.single.note, 'first point');
  });
}
