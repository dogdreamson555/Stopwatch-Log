import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/database/database.dart';
import 'package:stopwatch_log/providers/session_archive_provider.dart';
import 'package:stopwatch_log/providers/timer_provider.dart';

void main() {
  test('waits for draft restoration before allowing data import', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.saveCurrentTimerState(
      jsonEncode({
        'status': 'paused',
        'elapsedMs': 1000,
        'points': <Object>[],
        'sessionStartTime': '2026-06-24T10:00:00.000Z',
        'sessionId': 'active-session',
        'showSeconds': true,
        'showHundredths': true,
        'savedAt': '2026-06-24T10:00:01.000Z',
      }),
    );
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.close();
    });

    final canImport = await container
        .read(timerProvider.notifier)
        .prepareForDataImport();

    expect(canImport, isFalse);
    expect(container.read(timerProvider).isPaused, isTrue);
  });

  test('waits for a pending reset to clear the draft', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.close();
    });

    final notifier = container.read(timerProvider.notifier);
    notifier.start();
    notifier.reset();

    expect(await notifier.prepareForDataImport(), isTrue);
    expect(await db.loadCurrentTimerState(), isNull);
  });
}
