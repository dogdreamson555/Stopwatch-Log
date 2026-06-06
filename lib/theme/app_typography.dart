import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Microsoft YaHei UI';
  static const List<String> fontFamilyFallback = [
    'Microsoft YaHei',
    'Segoe UI',
    'Arial',
  ];

  static const String monoFontFamily = 'Cascadia Mono';
  static const List<String> monoFontFamilyFallback = [
    'Consolas',
    'Courier New',
  ];

  static const String displayFontFamily = 'Segoe UI Variable Display';
  static const List<String> displayFontFamilyFallback = ['Segoe UI', 'Arial'];

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static TextStyle display({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: displayFontFamily,
      fontFamilyFallback: displayFontFamilyFallback,
      fontFeatures: tabularFigures,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle mono({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: monoFontFamily,
      fontFamilyFallback: monoFontFamilyFallback,
      fontFeatures: tabularFigures,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
