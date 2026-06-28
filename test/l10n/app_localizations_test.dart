import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/l10n/app_localizations.dart';

void main() {
  test('provides all supported language variants', () {
    expect(const AppLocalizations(Locale('zh', 'CN')).settings, '设置');
    expect(const AppLocalizations(Locale('zh', 'TW')).settings, '設定');
    expect(const AppLocalizations(Locale('en')).settings, 'Settings');
    expect(const AppLocalizations(Locale('ja')).settings, '設定');

    expect(
      const AppLocalizations(Locale('zh', 'TW')).pointsCount(3),
      '🚩 標記 (3)',
    );
    expect(const AppLocalizations(Locale('en')).morePoints(2), '... 2 more');
  });
}
