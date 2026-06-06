import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stopwatch_log/database/database.dart';
import 'package:stopwatch_log/providers/session_archive_provider.dart';
import 'package:stopwatch_log/screens/timer_screen.dart';

void main() {
  testWidgets('shows the initial timer screen', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TimerScreen()),
      ),
    );

    expect(find.text('00'), findsAtLeastNWidgets(3));

    expect(find.text('小时'), findsOneWidget);
    expect(find.text('分钟'), findsOneWidget);
    expect(find.text('秒'), findsAtLeastNWidgets(1));

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
