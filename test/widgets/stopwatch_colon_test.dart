import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/widgets/stopwatch_colon.dart';

void main() {
  testWidgets('keeps its visual center fixed while scaling', (tester) async {
    Future<void> pumpColon(double colonScale) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: StopwatchColon(
              width: 30,
              height: 56,
              baseSize: 56,
              colonScale: colonScale,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    double visualCenterY() {
      final colon = find.byType(StopwatchColon);
      final dots = find.descendant(
        of: colon,
        matching: find.byType(DecoratedBox),
      );

      expect(dots, findsNWidgets(2));
      expect(tester.getSize(colon).height, 56);

      return (tester.getCenter(dots.at(0)).dy +
              tester.getCenter(dots.at(1)).dy) /
          2;
    }

    await pumpColon(0.7);
    final smallCenter = visualCenterY();

    await pumpColon(1.45);
    final largeCenter = visualCenterY();

    expect(largeCenter, closeTo(smallCenter, 0.001));
    expect(
      largeCenter,
      closeTo(tester.getCenter(find.byType(StopwatchColon)).dy, 0.001),
    );
  });
}
