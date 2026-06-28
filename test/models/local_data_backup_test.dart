import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/models/local_data_backup.dart';

void main() {
  test('round-trips a valid local data backup', () {
    final backup = LocalDataBackup(
      exportedAt: DateTime.utc(2026, 6, 24, 12),
      sessions: [
        LocalDataSession(
          id: 'session-1',
          date: DateTime.utc(2026, 6, 24, 10),
          totalElapsedMs: 120000,
          summary: 'done',
        ),
      ],
      points: [
        LocalDataPoint(
          id: 'point-1',
          sessionId: 'session-1',
          elapsedAtMs: 60000,
          createdAt: DateTime.utc(2026, 6, 24, 10, 1),
          note: 'halfway',
        ),
      ],
      settings: const {'app_language': 'en'},
      currentTimerState: null,
    );

    final restored = LocalDataBackup.fromJsonString(backup.toJsonString());

    expect(restored.exportedAt, backup.exportedAt);
    expect(restored.sessions.single.id, 'session-1');
    expect(restored.points.single.note, 'halfway');
    expect(restored.settings['app_language'], 'en');
  });

  test('rejects unsupported backup versions', () {
    final unsupported = '''
      {
        "application": "stopwatch_log",
        "formatVersion": 99,
        "exportedAt": "2026-06-24T12:00:00.000Z",
        "sessions": [],
        "points": [],
        "settings": {},
        "currentTimerState": null
      }
    ''';
    expect(
      () => LocalDataBackup.fromJsonString(unsupported),
      throwsFormatException,
    );
  });

  test('recovers missing sessions from legacy exported point rows', () {
    final legacyExport = '''
      {
        "application": "stopwatch_log",
        "formatVersion": 1,
        "exportedAt": "2026-06-24T12:00:00.000Z",
        "sessions": [],
        "points": [
          {
            "id": "point-1",
            "sessionId": "missing-session",
            "elapsedAtMs": 1000,
            "createdAt": "2026-06-24T12:00:01.000Z",
            "note": ""
          },
          {
            "id": "point-2",
            "sessionId": "missing-session",
            "elapsedAtMs": 2500,
            "createdAt": "2026-06-24T12:00:03.000Z",
            "note": "later"
          }
        ],
        "settings": {},
        "currentTimerState": null
      }
    ''';

    final restored = LocalDataBackup.fromJsonString(legacyExport);

    expect(restored.sessions, hasLength(1));
    expect(restored.sessions.single.id, 'missing-session');
    expect(restored.sessions.single.date, DateTime.utc(2026, 6, 24, 12, 0, 1));
    expect(restored.sessions.single.totalElapsedMs, 2500);
    expect(restored.points, hasLength(2));
  });
}
