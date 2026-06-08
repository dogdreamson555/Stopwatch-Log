import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/stopwatch_font_preset.dart';
import 'session_archive_provider.dart';

const _stopwatchFontPresetKey = 'stopwatch_font_preset';

class StopwatchSettings {
  final StopwatchFontPreset stopwatchFontPreset;

  const StopwatchSettings({
    this.stopwatchFontPreset = StopwatchFontPreset.defaultPreset,
  });

  StopwatchSettings copyWith({StopwatchFontPreset? stopwatchFontPreset}) {
    return StopwatchSettings(
      stopwatchFontPreset: stopwatchFontPreset ?? this.stopwatchFontPreset,
    );
  }
}

class StopwatchSettingsNotifier extends AsyncNotifier<StopwatchSettings> {
  @override
  Future<StopwatchSettings> build() async {
    final rawPreset = await ref
        .read(databaseProvider)
        .loadAppSetting(_stopwatchFontPresetKey);

    return StopwatchSettings(
      stopwatchFontPreset: StopwatchFontPreset.fromId(rawPreset),
    );
  }

  Future<void> setStopwatchFontPreset(StopwatchFontPreset preset) async {
    final current = state.value ?? const StopwatchSettings();
    if (current.stopwatchFontPreset == preset) return;

    final next = current.copyWith(stopwatchFontPreset: preset);
    state = AsyncData(next);

    try {
      await ref
          .read(databaseProvider)
          .saveAppSetting(_stopwatchFontPresetKey, preset.id);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final stopwatchSettingsProvider =
    AsyncNotifierProvider<StopwatchSettingsNotifier, StopwatchSettings>(
      StopwatchSettingsNotifier.new,
    );

final stopwatchFontPresetProvider = Provider<StopwatchFontPreset>((ref) {
  final settings = ref.watch(stopwatchSettingsProvider);
  return settings.value?.stopwatchFontPreset ??
      StopwatchFontPreset.defaultPreset;
});
