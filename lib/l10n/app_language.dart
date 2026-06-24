import 'package:flutter/widgets.dart';

enum AppLanguage {
  simplifiedChinese('zh_CN', Locale('zh', 'CN'), '简体中文'),
  traditionalChineseTaiwan('zh_TW', Locale('zh', 'TW'), '繁體中文（台灣）'),
  english('en', Locale('en'), 'English'),
  japanese('ja', Locale('ja'), '日本語');

  final String id;
  final Locale locale;
  final String nativeName;

  const AppLanguage(this.id, this.locale, this.nativeName);

  static AppLanguage fromId(String? id) {
    return values.firstWhere(
      (language) => language.id == id,
      orElse: () => simplifiedChinese,
    );
  }
}
