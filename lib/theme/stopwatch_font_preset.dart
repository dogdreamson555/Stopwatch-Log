import 'package:flutter/material.dart';

import 'app_typography.dart';

enum StopwatchFontPreset {
  segoeDisplay('segoe_display'),
  cascadiaMono('cascadia_mono'),
  consolas('consolas'),
  bahnschrift('bahnschrift');

  final String id;

  const StopwatchFontPreset(this.id);

  static const defaultPreset = segoeDisplay;

  static StopwatchFontPreset fromId(String? id) {
    return values.firstWhere(
      (preset) => preset.id == id,
      orElse: () => defaultPreset,
    );
  }

  String get label => switch (this) {
    segoeDisplay => 'Segoe UI',
    cascadiaMono => 'Cascadia Mono',
    consolas => 'Consolas',
    bahnschrift => 'Bahnschrift',
  };

  String get description => switch (this) {
    segoeDisplay => '默认数字字体，轻巧清晰',
    cascadiaMono => '等宽数字，冒号间距稳定',
    consolas => '经典等宽字体，对齐感强',
    bahnschrift => '更窄的数字，适合悬浮窗',
  };

  String get fontFamily => switch (this) {
    segoeDisplay => AppTypography.displayFontFamily,
    cascadiaMono => AppTypography.monoFontFamily,
    consolas => 'Consolas',
    bahnschrift => 'Bahnschrift',
  };

  List<String> get fontFamilyFallback => switch (this) {
    segoeDisplay => AppTypography.displayFontFamilyFallback,
    cascadiaMono => AppTypography.monoFontFamilyFallback,
    consolas => const ['Cascadia Mono', 'Courier New'],
    bahnschrift => const ['Segoe UI Variable Display', 'Segoe UI', 'Arial'],
  };

  TextStyle textStyle({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontFeatures: AppTypography.tabularFigures,
      letterSpacing: 0,
      height: height,
    );
  }
}
