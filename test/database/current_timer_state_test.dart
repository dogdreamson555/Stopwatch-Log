import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/database/database.dart';

void main() {
  test('saves, overwrites, and clears the current timer draft', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.loadCurrentTimerState(), isNull);

    await db.saveCurrentTimerState('first payload');
    expect(await db.loadCurrentTimerState(), 'first payload');

    await db.saveCurrentTimerState('second payload');
    expect(await db.loadCurrentTimerState(), 'second payload');

    await db.clearCurrentTimerState();
    expect(await db.loadCurrentTimerState(), isNull);
  });
}
