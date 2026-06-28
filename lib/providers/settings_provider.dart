import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_language.dart';
import '../services/custom_font_service.dart';
import '../theme/stopwatch_font_preset.dart';
import 'session_archive_provider.dart';

const _stopwatchFontPresetKey = 'stopwatch_font_preset';
const _customFontPathKey = 'stopwatch_custom_font_path';
const _customFontFamilyKey = 'stopwatch_custom_font_family';
const _customFontLabelKey = 'stopwatch_custom_font_label';
const _digitScaleKey = 'stopwatch_digit_scale';
const _colonScaleKey = 'stopwatch_colon_scale';
const _separatorSpacingKey = 'stopwatch_separator_spacing';
const _appLanguageKey = 'app_language';

class StopwatchSettings {
  final AppLanguage appLanguage;
  final StopwatchFontPreset stopwatchFontPreset;
  final String? customFontPath;
  final String? customFontFamily;
  final String? customFontLabel;
  final double digitScale;
  final double colonScale;
  final double separatorSpacing;

  const StopwatchSettings({
    this.appLanguage = AppLanguage.simplifiedChinese,
    this.stopwatchFontPreset = StopwatchFontPreset.defaultPreset,
    this.customFontPath,
    this.customFontFamily,
    this.customFontLabel,
    this.digitScale = 1,
    this.colonScale = 1,
    this.separatorSpacing = 4,
  });

  bool get hasCustomFont => customFontPath != null && customFontFamily != null;

  StopwatchFontPreset get effectiveFontPreset {
    if (stopwatchFontPreset == StopwatchFontPreset.custom && !hasCustomFont) {
      return StopwatchFontPreset.defaultPreset;
    }
    return stopwatchFontPreset;
  }

  String? get effectiveCustomFontFamily {
    if (effectiveFontPreset != StopwatchFontPreset.custom) return null;
    return customFontFamily;
  }

  StopwatchSettings copyWith({
    AppLanguage? appLanguage,
    StopwatchFontPreset? stopwatchFontPreset,
    String? customFontPath,
    String? customFontFamily,
    String? customFontLabel,
    double? digitScale,
    double? colonScale,
    double? separatorSpacing,
  }) {
    return StopwatchSettings(
      appLanguage: appLanguage ?? this.appLanguage,
      stopwatchFontPreset: stopwatchFontPreset ?? this.stopwatchFontPreset,
      customFontPath: customFontPath ?? this.customFontPath,
      customFontFamily: customFontFamily ?? this.customFontFamily,
      customFontLabel: customFontLabel ?? this.customFontLabel,
      digitScale: digitScale ?? this.digitScale,
      colonScale: colonScale ?? this.colonScale,
      separatorSpacing: separatorSpacing ?? this.separatorSpacing,
    );
  }
}

class StopwatchSettingsNotifier extends AsyncNotifier<StopwatchSettings> {
  @override
  Future<StopwatchSettings> build() async {
    final db = ref.read(databaseProvider);
    final rawLanguage = await db.loadAppSetting(_appLanguageKey);
    final rawPreset = await db.loadAppSetting(_stopwatchFontPresetKey);
    final customFontPath = await db.loadAppSetting(_customFontPathKey);
    final customFontFamily = await db.loadAppSetting(_customFontFamilyKey);
    final customFontLabel = await db.loadAppSetting(_customFontLabelKey);
    final digitScale = _parseDoubleSetting(
      await db.loadAppSetting(_digitScaleKey),
      fallback: 1,
      min: 0.75,
      max: 1.35,
    );
    final colonScale = _parseDoubleSetting(
      await db.loadAppSetting(_colonScaleKey),
      fallback: 1,
      min: 0.7,
      max: 1.45,
    );
    final separatorSpacing = _parseDoubleSetting(
      await db.loadAppSetting(_separatorSpacingKey),
      fallback: 4,
      min: 0,
      max: 14,
    );

    if (customFontPath != null && customFontFamily != null) {
      try {
        await CustomFontService.loadFont(
          path: customFontPath,
          family: customFontFamily,
        );
      } catch (_) {
        // Keep the saved choice visible; Text falls back if the file is gone.
      }
    }

    return StopwatchSettings(
      appLanguage: AppLanguage.fromId(rawLanguage),
      stopwatchFontPreset: StopwatchFontPreset.fromId(rawPreset),
      customFontPath: customFontPath,
      customFontFamily: customFontFamily,
      customFontLabel: customFontLabel,
      digitScale: digitScale,
      colonScale: colonScale,
      separatorSpacing: separatorSpacing,
    );
  }

  Future<void> setAppLanguage(AppLanguage language) async {
    final current = state.value ?? const StopwatchSettings();
    if (current.appLanguage == language) return;

    final next = current.copyWith(appLanguage: language);
    state = AsyncData(next);

    try {
      await ref
          .read(databaseProvider)
          .saveAppSetting(_appLanguageKey, language.id);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setStopwatchFontPreset(StopwatchFontPreset preset) async {
    final current = state.value ?? const StopwatchSettings();
    if (preset == StopwatchFontPreset.custom && !current.hasCustomFont) return;
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

  Future<void> importCustomFont(String sourcePath) async {
    final importedFont = await CustomFontService.importFont(sourcePath);
    final current = state.value ?? const StopwatchSettings();
    final next = current.copyWith(
      stopwatchFontPreset: StopwatchFontPreset.custom,
      customFontPath: importedFont.path,
      customFontFamily: importedFont.family,
      customFontLabel: importedFont.label,
    );

    state = AsyncData(next);

    try {
      final db = ref.read(databaseProvider);
      await Future.wait([
        db.saveAppSetting(
          _stopwatchFontPresetKey,
          StopwatchFontPreset.custom.id,
        ),
        db.saveAppSetting(_customFontPathKey, importedFont.path),
        db.saveAppSetting(_customFontFamilyKey, importedFont.family),
        db.saveAppSetting(_customFontLabelKey, importedFont.label),
      ]);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> setDigitScale(double value) {
    return _updateDoubleSetting(
      key: _digitScaleKey,
      value: value,
      min: 0.75,
      max: 1.35,
      apply: (settings, clampedValue) =>
          settings.copyWith(digitScale: clampedValue),
    );
  }

  Future<void> setColonScale(double value) {
    return _updateDoubleSetting(
      key: _colonScaleKey,
      value: value,
      min: 0.7,
      max: 1.45,
      apply: (settings, clampedValue) =>
          settings.copyWith(colonScale: clampedValue),
    );
  }

  Future<void> setSeparatorSpacing(double value) {
    return _updateDoubleSetting(
      key: _separatorSpacingKey,
      value: value,
      min: 0,
      max: 14,
      apply: (settings, clampedValue) =>
          settings.copyWith(separatorSpacing: clampedValue),
    );
  }

  Future<void> resetDisplayTuning() async {
    final current = state.value ?? const StopwatchSettings();
    final next = current.copyWith(
      digitScale: 1,
      colonScale: 1,
      separatorSpacing: 4,
    );
    state = AsyncData(next);

    try {
      final db = ref.read(databaseProvider);
      await Future.wait([
        db.saveAppSetting(_digitScaleKey, '1.000'),
        db.saveAppSetting(_colonScaleKey, '1.000'),
        db.saveAppSetting(_separatorSpacingKey, '4.000'),
      ]);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _updateDoubleSetting({
    required String key,
    required double value,
    required double min,
    required double max,
    required StopwatchSettings Function(StopwatchSettings, double) apply,
  }) async {
    final clampedValue = value.clamp(min, max).toDouble();
    final current = state.value ?? const StopwatchSettings();
    final next = apply(current, clampedValue);
    state = AsyncData(next);

    try {
      await ref
          .read(databaseProvider)
          .saveAppSetting(key, clampedValue.toStringAsFixed(3));
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
  return settings.value?.effectiveFontPreset ??
      StopwatchFontPreset.defaultPreset;
});

final stopwatchDisplaySettingsProvider = Provider<StopwatchSettings>((ref) {
  final settings = ref.watch(stopwatchSettingsProvider);
  return settings.value ?? const StopwatchSettings();
});

final appLanguageProvider = Provider<AppLanguage>((ref) {
  final settings = ref.watch(stopwatchSettingsProvider);
  return settings.value?.appLanguage ?? AppLanguage.simplifiedChinese;
});

double _parseDoubleSetting(
  String? raw, {
  required double fallback,
  required double min,
  required double max,
}) {
  final value = raw == null ? null : double.tryParse(raw);
  return (value ?? fallback).clamp(min, max).toDouble();
}
