import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/widgets/stable_digit_text.dart';

void main() {
  testWidgets('keeps the same layout size for every two-digit value', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 40, height: 1);

    Future<Size> pumpValue(String value) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: StableDigitText(value: '00', style: style),
          ),
        ),
      );

      if (value != '00') {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: StableDigitText(value: value, style: style),
            ),
          ),
        );
      }

      return tester.getSize(find.byType(StableDigitText));
    }

    final wideValueSize = await pumpValue('00');
    final narrowValueSize = await pumpValue('01');
    final otherValueSize = await pumpValue('27');

    expect(narrowValueSize, wideValueSize);
    expect(otherValueSize, wideValueSize);
  });

  testWidgets('adds one fixed-width cell when the digit count grows', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 40, height: 1);

    Future<Size> pumpValue(String value) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: StableDigitText(value: value, style: style),
          ),
        ),
      );
      return tester.getSize(find.byType(StableDigitText));
    }

    final twoDigits = await pumpValue('99');
    final threeDigits = await pumpValue('100');

    expect(threeDigits.height, twoDigits.height);
    expect(threeDigits.width, closeTo(twoDigits.width * 1.5, 0.001));
  });
}
