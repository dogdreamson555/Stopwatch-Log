import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/models/timer_point.dart';
import 'package:stopwatch_log/models/timer_session.dart';
import 'package:stopwatch_log/providers/timer_provider.dart';

void main() {
  group('TimerPoint serialization', () {
    test('preserves point fields', () {
      final createdAt = DateTime(2026, 6, 6, 10, 30, 12);
      final point = TimerPoint(
        id: 'point-1',
        elapsedAt: const Duration(minutes: 1, seconds: 23, milliseconds: 450),
        createdAt: createdAt,
        note: 'checkpoint',
      );

      final restored = TimerPoint.fromJson(point.toJson());

      expect(restored.id, 'point-1');
      expect(restored.elapsedAt, point.elapsedAt);
      expect(restored.createdAt, createdAt);
      expect(restored.note, 'checkpoint');
    });
  });

  group('TimerSession serialization', () {
    test('preserves session fields and points', () {
      final session = TimerSession(
        id: 'session-1',
        date: DateTime(2026, 6, 6, 11),
        totalElapsed: const Duration(minutes: 4, seconds: 5),
        summary: 'solid focus block',
        points: [
          TimerPoint(
            id: 'point-1',
            elapsedAt: const Duration(seconds: 30),
            createdAt: DateTime(2026, 6, 6, 11, 0, 30),
            note: 'first note',
          ),
        ],
      );

      final restored = TimerSession.fromJson(session.toJson());

      expect(restored.id, 'session-1');
      expect(restored.date, session.date);
      expect(restored.totalElapsed, session.totalElapsed);
      expect(restored.summary, 'solid focus block');
      expect(restored.points, hasLength(1));
      expect(restored.points.single.id, 'point-1');
      expect(restored.points.single.note, 'first note');
    });
  });

  group('TimerState draft serialization', () {
    test('preserves a paused active draft', () {
      final sessionStartTime = DateTime(2026, 6, 6, 9);
      final state = TimerState(
        status: TimerStatus.paused,
        elapsed: const Duration(minutes: 12, seconds: 34),
        sessionId: 'draft-session',
        sessionStartTime: sessionStartTime,
        showSeconds: false,
        showHundredths: false,
        points: [
          TimerPoint(
            id: 'point-1',
            elapsedAt: const Duration(minutes: 2),
            createdAt: DateTime(2026, 6, 6, 9, 2),
            note: 'pause here',
          ),
        ],
      );

      final restored = TimerState.fromDraftJson(
        state.toDraftJson(DateTime(2026, 6, 6, 9, 12, 34)),
      );

      expect(restored.status, TimerStatus.paused);
      expect(restored.elapsed, state.elapsed);
      expect(restored.sessionId, 'draft-session');
      expect(restored.sessionStartTime, sessionStartTime);
      expect(restored.showSeconds, isFalse);
      expect(restored.showHundredths, isFalse);
      expect(restored.points, hasLength(1));
      expect(restored.points.single.note, 'pause here');
    });

    test('advances running drafts by the time spent away', () {
      final savedAt = DateTime.now().subtract(const Duration(seconds: 2));
      final state = TimerState(
        status: TimerStatus.running,
        elapsed: const Duration(milliseconds: 1500),
        sessionId: 'running-session',
        sessionStartTime: DateTime(2026, 6, 6, 9),
      );

      final restored = TimerState.fromDraftJson(state.toDraftJson(savedAt));

      expect(restored.status, TimerStatus.running);
      expect(
        restored.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 3500)),
      );
      expect(restored.elapsed, lessThan(const Duration(milliseconds: 4500)));
    });
  });
}
