import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/database/database.dart';
import 'package:stopwatch_log/models/local_data_backup.dart';

void main() {
  test('exports and restores sessions, points, draft, and settings', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.insertSession(
      SessionsCompanion.insert(
        id: 'session-1',
        date: DateTime.utc(2026, 6, 24, 10),
        totalElapsedMs: 120000,
        summary: const Value('reviewed'),
      ),
    );
    await db.insertPoints([
      PointsCompanion.insert(
        id: 'point-1',
        sessionId: 'session-1',
        elapsedAtMs: 60000,
        createdAt: DateTime.utc(2026, 6, 24, 10, 1),
        note: const Value('halfway'),
      ),
    ]);
    await db.saveAppSetting('app_language', 'en');
    await db.saveCurrentTimerState(
      jsonEncode({
        'status': 'paused',
        'elapsedMs': 45000,
        'points': <Object>[],
        'sessionStartTime': '2026-06-24T11:00:00.000Z',
        'sessionId': 'active-session',
        'showSeconds': true,
        'showHundredths': false,
        'savedAt': '2026-06-24T11:01:00.000Z',
      }),
    );

    final backup = await db.createLocalDataBackup();
    await db.replaceLocalData(
      LocalDataBackup(
        exportedAt: DateTime.now(),
        sessions: const [],
        points: const [],
        settings: const {},
        currentTimerState: null,
      ),
    );
    expect(await db.allSessions(), isEmpty);

    final parsed = LocalDataBackup.fromJsonString(backup.toJsonString());
    await db.replaceLocalData(parsed);

    final sessions = await db.allSessions();
    expect(sessions.single.id, 'session-1');
    expect(sessions.single.summary, 'reviewed');
    expect((await db.pointsForSession('session-1')).single.note, 'halfway');
    expect(await db.loadAppSetting('app_language'), 'en');

    final draft =
        jsonDecode((await db.loadCurrentTimerState())!) as Map<String, dynamic>;
    expect(draft['status'], 'paused');
    expect(draft['elapsedMs'], 45000);
    expect(draft['sessionId'], 'active-session');
    expect(
      DateTime.parse(
        draft['savedAt'] as String,
      ).difference(DateTime.now()).abs(),
      lessThan(const Duration(seconds: 5)),
    );
  });

  test('exports legacy orphan points with recovered sessions', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.customStatement('PRAGMA foreign_keys = OFF');
    await db.insertPoints([
      PointsCompanion.insert(
        id: 'orphan-point-1',
        sessionId: 'legacy-session',
        elapsedAtMs: 1000,
        createdAt: DateTime.utc(2026, 6, 25, 12),
      ),
      PointsCompanion.insert(
        id: 'orphan-point-2',
        sessionId: 'legacy-session',
        elapsedAtMs: 2500,
        createdAt: DateTime.utc(2026, 6, 25, 12, 0, 3),
        note: const Value('later'),
      ),
    ]);
    await db.customStatement('PRAGMA foreign_keys = ON');

    final backup = await db.createLocalDataBackup();

    expect(backup.sessions, hasLength(1));
    expect(backup.sessions.single.id, 'legacy-session');
    expect(backup.sessions.single.date.toUtc(), DateTime.utc(2026, 6, 25, 12));
    expect(backup.sessions.single.totalElapsedMs, 2500);

    await db.replaceLocalData(
      LocalDataBackup(
        exportedAt: DateTime.now(),
        sessions: const [],
        points: const [],
        settings: const {},
        currentTimerState: null,
      ),
    );
    final parsed = LocalDataBackup.fromJsonString(backup.toJsonString());
    await db.replaceLocalData(parsed);

    expect((await db.allSessions()).single.id, 'legacy-session');
    expect((await db.pointsForSession('legacy-session')), hasLength(2));
  });
  test('rolls back the whole import when a database write fails', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.insertSession(
      SessionsCompanion.insert(
        id: 'original',
        date: DateTime.utc(2026, 6, 24),
        totalElapsedMs: 1000,
      ),
    );
    await db.saveAppSetting('app_language', 'ja');

    final duplicateSessions = LocalDataBackup(
      exportedAt: DateTime.now(),
      sessions: [
        LocalDataSession(
          id: 'duplicate',
          date: DateTime.utc(2026, 6, 23),
          totalElapsedMs: 2000,
          summary: '',
        ),
        LocalDataSession(
          id: 'duplicate',
          date: DateTime.utc(2026, 6, 22),
          totalElapsedMs: 3000,
          summary: '',
        ),
      ],
      points: const [],
      settings: const {'app_language': 'en'},
      currentTimerState: null,
    );

    await expectLater(
      db.replaceLocalData(duplicateSessions),
      throwsA(isA<Exception>()),
    );

    expect((await db.allSessions()).single.id, 'original');
    expect(await db.loadAppSetting('app_language'), 'ja');
  });
}
