import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch_log/database/database.dart';
import 'package:stopwatch_log/l10n/app_language.dart';
import 'package:stopwatch_log/providers/session_archive_provider.dart';
import 'package:stopwatch_log/providers/settings_provider.dart';

void main() {
  test('persists and restores the selected app language', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final firstContainer = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    expect(
      (await firstContainer.read(stopwatchSettingsProvider.future)).appLanguage,
      AppLanguage.simplifiedChinese,
    );

    await firstContainer
        .read(stopwatchSettingsProvider.notifier)
        .setAppLanguage(AppLanguage.japanese);
    expect(
      firstContainer.read(stopwatchSettingsProvider).value!.appLanguage,
      AppLanguage.japanese,
    );
    expect(await db.loadAppSetting('app_language'), 'ja');
    firstContainer.dispose();

    final restoredContainer = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(restoredContainer.dispose);

    expect(
      (await restoredContainer.read(
        stopwatchSettingsProvider.future,
      )).appLanguage,
      AppLanguage.japanese,
    );
  });
}
