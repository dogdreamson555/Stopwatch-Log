import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_language.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static final supportedLocales = AppLanguage.values
      .map((language) => language.locale)
      .toList(growable: false);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('zh', 'CN'));
  }

  String get _languageKey {
    if (locale.languageCode == 'ja') return 'ja';
    if (locale.languageCode == 'en') return 'en';
    if (locale.languageCode == 'zh' &&
        (locale.countryCode == 'TW' || locale.scriptCode == 'Hant')) {
      return 'zh_TW';
    }
    return 'zh_CN';
  }

  String _text(String key) {
    return _translations[_languageKey]?[key] ??
        _translations['zh_CN']![key] ??
        key;
  }

  String get appTitle => _text('appTitle');
  String get settings => _text('settings');
  String get history => _text('history');
  String get switchToFloating => _text('switchToFloating');
  String get exitFloating => _text('exitFloating');
  String get minimize => _text('minimize');
  String get maximizeRestore => _text('maximizeRestore');
  String get closeApp => _text('closeApp');
  String get hours => _text('hours');
  String get minutes => _text('minutes');
  String get seconds => _text('seconds');
  String get start => _text('start');
  String get pause => _text('pause');
  String get markPoint => _text('markPoint');
  String get resume => _text('resume');
  String get finish => _text('finish');
  String get pointNoteHint => _text('pointNoteHint');
  String get loadFailed => _text('loadFailed');
  String get noHistory => _text('noHistory');
  String get startFirstSession => _text('startFirstSession');
  String get deleted => _text('deleted');
  String get collapseSummary => _text('collapseSummary');
  String get expandSummary => _text('expandSummary');
  String get summary => _text('summary');
  String get noSummary => _text('noSummary');
  String pointsCount(int count) =>
      _text('pointsCount').replaceAll('{count}', '$count');
  String morePoints(int count) =>
      _text('morePoints').replaceAll('{count}', '$count');
  String get summarySaved => _text('summarySaved');
  String get reviewArchive => _text('reviewArchive');
  String get save => _text('save');
  String get date => _text('date');
  String get netDuration => _text('netDuration');
  String get pointStream => _text('pointStream');
  String get noPointsThisSession => _text('noPointsThisSession');
  String get selfSummary => _text('selfSummary');
  String get summaryHint => _text('summaryHint');
  String get general => _text('general');
  String get language => _text('language');
  String get stopwatchDisplay => _text('stopwatchDisplay');
  String get digitSize => _text('digitSize');
  String get colonSize => _text('colonSize');
  String get digitColonSpacing => _text('digitColonSpacing');
  String get data => _text('data');
  String get localData => _text('localData');
  String get localDataPlaceholder => _text('localDataPlaceholder');
  String get exportData => _text('exportData');
  String get exportDataDescription => _text('exportDataDescription');
  String get importData => _text('importData');
  String get importDataDescription => _text('importDataDescription');
  String get backupFile => _text('backupFile');
  String get exportAction => _text('exportAction');
  String get dataExported => _text('dataExported');
  String get dataExportFailed => _text('dataExportFailed');
  String get confirmDataImport => _text('confirmDataImport');
  String get importDataWarning => _text('importDataWarning');
  String get cancel => _text('cancel');
  String get replaceData => _text('replaceData');
  String dataImported(int sessions, int points) => _text(
    'dataImported',
  ).replaceAll('{sessions}', '$sessions').replaceAll('{points}', '$points');
  String get invalidBackupFile => _text('invalidBackupFile');
  String get dataImportFailed => _text('dataImportFailed');
  String get stopTimerBeforeImport => _text('stopTimerBeforeImport');
  String get fontFile => _text('fontFile');
  String get importAction => _text('importAction');
  String get fontImported => _text('fontImported');
  String get fontFileMissing => _text('fontFileMissing');
  String get unsupportedFontFile => _text('unsupportedFontFile');
  String get fontPathRequired => _text('fontPathRequired');
  String get fontImportFailed => _text('fontImportFailed');
  String get importedLocalFont => _text('importedLocalFont');
  String get importFontTypes => _text('importFontTypes');
  String get importFont => _text('importFont');
  String get resetDisplay => _text('resetDisplay');
  String get resetDefault => _text('resetDefault');
  String get customFont => _text('customFont');
  String get segoeDescription => _text('segoeDescription');
  String get cascadiaDescription => _text('cascadiaDescription');
  String get consolasDescription => _text('consolasDescription');
  String get bahnschriftDescription => _text('bahnschriftDescription');
  String get customFontDescription => _text('customFontDescription');
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.values.any(
      (language) =>
          language.locale.languageCode == locale.languageCode &&
          (language.locale.countryCode == null ||
              language.locale.countryCode == locale.countryCode),
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _translations = <String, Map<String, String>>{
  'zh_CN': {
    'appTitle': 'Stopwatch Log',
    'settings': '设置',
    'history': '历史记录',
    'switchToFloating': '切换到悬浮窗',
    'exitFloating': '退出悬浮窗',
    'minimize': '最小化',
    'maximizeRestore': '最大化/还原',
    'closeApp': '关闭应用',
    'hours': '小时',
    'minutes': '分钟',
    'seconds': '秒',
    'start': '开始',
    'pause': '暂停',
    'markPoint': '打点',
    'resume': '继续',
    'finish': '结束',
    'pointNoteHint': '记录此刻的想法…',
    'loadFailed': '加载失败',
    'noHistory': '还没有计时记录',
    'startFirstSession': '开始第一次专注计时吧',
    'deleted': '已删除',
    'collapseSummary': '收起摘要',
    'expandSummary': '展开摘要',
    'summary': '📝 总结',
    'noSummary': '（未填写总结）',
    'pointsCount': '🚩 打点 ({count})',
    'morePoints': '... 还有 {count} 条',
    'summarySaved': '总结已保存 ✓',
    'reviewArchive': '复盘归档',
    'save': '保存',
    'date': '日期',
    'netDuration': '净总时长',
    'pointStream': '打点流',
    'noPointsThisSession': '本次没有打点记录',
    'selfSummary': '自我总结',
    'summaryHint': '写下对这段时间的反思、收获或感受…',
    'general': '通用',
    'language': '语言',
    'stopwatchDisplay': '秒表显示',
    'digitSize': '数字大小',
    'colonSize': '冒号大小',
    'digitColonSpacing': '数字与冒号间距',
    'data': '数据',
    'localData': '本地数据',
    'localDataPlaceholder': '后续可放入导入、导出和备份相关功能',
    'exportData': '导出本地数据',
    'exportDataDescription': '备份历史记录、当前计时和应用设置',
    'importData': '导入本地数据',
    'importDataDescription': '从 Stopwatch Log JSON 备份恢复数据',
    'backupFile': 'Stopwatch Log 备份',
    'exportAction': '导出',
    'dataExported': '本地数据已导出',
    'dataExportFailed': '导出失败，请检查保存位置',
    'confirmDataImport': '确认导入数据？',
    'importDataWarning': '导入会完整替换当前的历史记录、当前计时和应用设置。此操作无法撤销。',
    'cancel': '取消',
    'replaceData': '替换数据',
    'dataImported': '已导入 {sessions} 个会话和 {points} 个打点',
    'invalidBackupFile': '备份文件无效或版本不受支持',
    'dataImportFailed': '导入失败，现有数据未被更改',
    'stopTimerBeforeImport': '请先结束或重置当前计时，再导入数据',
    'fontFile': '字体文件',
    'importAction': '导入',
    'fontImported': '字体已导入',
    'fontFileMissing': '字体文件不存在',
    'unsupportedFontFile': '仅支持 .ttf、.otf、.ttc 字体文件',
    'fontPathRequired': '请输入字体文件路径',
    'fontImportFailed': '导入失败，请检查字体文件',
    'importedLocalFont': '已导入本地字体',
    'importFontTypes': '导入 .ttf / .otf / .ttc',
    'importFont': '导入字体',
    'resetDisplay': '恢复默认显示参数',
    'resetDefault': '恢复默认',
    'customFont': '自定义字体',
    'segoeDescription': '默认数字字体，轻巧清晰',
    'cascadiaDescription': '等宽数字，冒号间距稳定',
    'consolasDescription': '经典等宽字体，对齐感强',
    'bahnschriftDescription': '更窄的数字，适合悬浮窗',
    'customFontDescription': '使用导入的本地字体文件',
  },
  'zh_TW': {
    'appTitle': 'Stopwatch Log',
    'settings': '設定',
    'history': '歷史記錄',
    'switchToFloating': '切換至懸浮視窗',
    'exitFloating': '退出懸浮視窗',
    'minimize': '最小化',
    'maximizeRestore': '最大化/還原',
    'closeApp': '關閉應用程式',
    'hours': '小時',
    'minutes': '分鐘',
    'seconds': '秒',
    'start': '開始',
    'pause': '暫停',
    'markPoint': '標記',
    'resume': '繼續',
    'finish': '結束',
    'pointNoteHint': '記錄此刻的想法…',
    'loadFailed': '載入失敗',
    'noHistory': '尚無計時記錄',
    'startFirstSession': '開始第一次專注計時吧',
    'deleted': '已刪除',
    'collapseSummary': '收合摘要',
    'expandSummary': '展開摘要',
    'summary': '📝 總結',
    'noSummary': '（未填寫總結）',
    'pointsCount': '🚩 標記 ({count})',
    'morePoints': '... 還有 {count} 筆',
    'summarySaved': '總結已儲存 ✓',
    'reviewArchive': '回顧歸檔',
    'save': '儲存',
    'date': '日期',
    'netDuration': '淨總時長',
    'pointStream': '標記記錄',
    'noPointsThisSession': '本次沒有標記記錄',
    'selfSummary': '自我總結',
    'summaryHint': '寫下對這段時間的反思、收穫或感受…',
    'general': '一般',
    'language': '語言',
    'stopwatchDisplay': '碼錶顯示',
    'digitSize': '數字大小',
    'colonSize': '冒號大小',
    'digitColonSpacing': '數字與冒號間距',
    'data': '資料',
    'localData': '本機資料',
    'localDataPlaceholder': '之後可加入匯入、匯出與備份功能',
    'exportData': '匯出本機資料',
    'exportDataDescription': '備份歷史記錄、目前計時與應用程式設定',
    'importData': '匯入本機資料',
    'importDataDescription': '從 Stopwatch Log JSON 備份還原資料',
    'backupFile': 'Stopwatch Log 備份',
    'exportAction': '匯出',
    'dataExported': '本機資料已匯出',
    'dataExportFailed': '匯出失敗，請檢查儲存位置',
    'confirmDataImport': '確認匯入資料？',
    'importDataWarning': '匯入會完整取代目前的歷史記錄、目前計時與應用程式設定。此操作無法復原。',
    'cancel': '取消',
    'replaceData': '取代資料',
    'dataImported': '已匯入 {sessions} 個工作階段與 {points} 個標記',
    'invalidBackupFile': '備份檔案無效或版本不受支援',
    'dataImportFailed': '匯入失敗，現有資料未被變更',
    'stopTimerBeforeImport': '請先結束或重設目前計時，再匯入資料',
    'fontFile': '字型檔案',
    'importAction': '匯入',
    'fontImported': '字型已匯入',
    'fontFileMissing': '字型檔案不存在',
    'unsupportedFontFile': '僅支援 .ttf、.otf、.ttc 字型檔案',
    'fontPathRequired': '請輸入字型檔案路徑',
    'fontImportFailed': '匯入失敗，請檢查字型檔案',
    'importedLocalFont': '已匯入本機字型',
    'importFontTypes': '匯入 .ttf / .otf / .ttc',
    'importFont': '匯入字型',
    'resetDisplay': '還原預設顯示參數',
    'resetDefault': '還原預設',
    'customFont': '自訂字型',
    'segoeDescription': '預設數字字型，輕巧清晰',
    'cascadiaDescription': '等寬數字，冒號間距穩定',
    'consolasDescription': '經典等寬字型，對齊感強',
    'bahnschriftDescription': '較窄的數字，適合懸浮視窗',
    'customFontDescription': '使用匯入的本機字型檔案',
  },
  'en': {
    'appTitle': 'Stopwatch Log',
    'settings': 'Settings',
    'history': 'History',
    'switchToFloating': 'Switch to floating window',
    'exitFloating': 'Exit floating window',
    'minimize': 'Minimize',
    'maximizeRestore': 'Maximize/Restore',
    'closeApp': 'Close app',
    'hours': 'Hours',
    'minutes': 'Minutes',
    'seconds': 'Seconds',
    'start': 'Start',
    'pause': 'Pause',
    'markPoint': 'Mark point',
    'resume': 'Resume',
    'finish': 'Finish',
    'pointNoteHint': 'Capture what you are thinking…',
    'loadFailed': 'Failed to load',
    'noHistory': 'No timing sessions yet',
    'startFirstSession': 'Start your first focus session',
    'deleted': 'Deleted',
    'collapseSummary': 'Collapse summary',
    'expandSummary': 'Expand summary',
    'summary': '📝 Summary',
    'noSummary': '(No summary)',
    'pointsCount': '🚩 Points ({count})',
    'morePoints': '... {count} more',
    'summarySaved': 'Summary saved ✓',
    'reviewArchive': 'Session Review',
    'save': 'Save',
    'date': 'Date',
    'netDuration': 'Net duration',
    'pointStream': 'Timeline',
    'noPointsThisSession': 'No points recorded in this session',
    'selfSummary': 'Reflection',
    'summaryHint': 'Write down your reflections, takeaways, or feelings…',
    'general': 'General',
    'language': 'Language',
    'stopwatchDisplay': 'Stopwatch display',
    'digitSize': 'Digit size',
    'colonSize': 'Colon size',
    'digitColonSpacing': 'Digit and colon spacing',
    'data': 'Data',
    'localData': 'Local data',
    'localDataPlaceholder': 'Import, export, and backup options can go here',
    'exportData': 'Export local data',
    'exportDataDescription':
        'Back up history, the current timer, and app settings',
    'importData': 'Import local data',
    'importDataDescription': 'Restore from a Stopwatch Log JSON backup',
    'backupFile': 'Stopwatch Log backup',
    'exportAction': 'Export',
    'dataExported': 'Local data exported',
    'dataExportFailed': 'Export failed. Check the save location',
    'confirmDataImport': 'Import this backup?',
    'importDataWarning':
        'Importing completely replaces the current history, timer, and app settings. This cannot be undone.',
    'cancel': 'Cancel',
    'replaceData': 'Replace data',
    'dataImported': 'Imported {sessions} sessions and {points} points',
    'invalidBackupFile': 'The backup is invalid or uses an unsupported version',
    'dataImportFailed': 'Import failed. Existing data was not changed',
    'stopTimerBeforeImport':
        'Finish or reset the current timer before importing',
    'fontFile': 'Font file',
    'importAction': 'Import',
    'fontImported': 'Font imported',
    'fontFileMissing': 'Font file not found',
    'unsupportedFontFile': 'Only .ttf, .otf, and .ttc files are supported',
    'fontPathRequired': 'Please select a font file',
    'fontImportFailed': 'Import failed. Please check the font file',
    'importedLocalFont': 'Local font imported',
    'importFontTypes': 'Import .ttf / .otf / .ttc',
    'importFont': 'Import font',
    'resetDisplay': 'Reset display settings',
    'resetDefault': 'Reset to defaults',
    'customFont': 'Custom font',
    'segoeDescription': 'Light, clear default digits',
    'cascadiaDescription': 'Monospaced digits with stable colon spacing',
    'consolasDescription': 'Classic monospaced font with strong alignment',
    'bahnschriftDescription': 'Narrower digits suited to the floating window',
    'customFontDescription': 'Use an imported local font file',
  },
  'ja': {
    'appTitle': 'Stopwatch Log',
    'settings': '設定',
    'history': '履歴',
    'switchToFloating': 'フローティング表示に切り替え',
    'exitFloating': 'フローティング表示を終了',
    'minimize': '最小化',
    'maximizeRestore': '最大化/元に戻す',
    'closeApp': 'アプリを閉じる',
    'hours': '時間',
    'minutes': '分',
    'seconds': '秒',
    'start': '開始',
    'pause': '一時停止',
    'markPoint': 'ポイントを記録',
    'resume': '再開',
    'finish': '終了',
    'pointNoteHint': '今考えていることを記録…',
    'loadFailed': '読み込みに失敗しました',
    'noHistory': '計時履歴はまだありません',
    'startFirstSession': '最初の集中タイマーを始めましょう',
    'deleted': '削除しました',
    'collapseSummary': '概要を閉じる',
    'expandSummary': '概要を展開',
    'summary': '📝 まとめ',
    'noSummary': '（まとめは未入力です）',
    'pointsCount': '🚩 ポイント ({count})',
    'morePoints': '... あと {count} 件',
    'summarySaved': 'まとめを保存しました ✓',
    'reviewArchive': 'セッションの振り返り',
    'save': '保存',
    'date': '日付',
    'netDuration': '正味時間',
    'pointStream': 'ポイント履歴',
    'noPointsThisSession': 'このセッションにはポイントがありません',
    'selfSummary': '振り返り',
    'summaryHint': 'この時間の気づき、学び、感想を書きましょう…',
    'general': '一般',
    'language': '言語',
    'stopwatchDisplay': 'ストップウォッチ表示',
    'digitSize': '数字のサイズ',
    'colonSize': 'コロンのサイズ',
    'digitColonSpacing': '数字とコロンの間隔',
    'data': 'データ',
    'localData': 'ローカルデータ',
    'localDataPlaceholder': 'インポート、エクスポート、バックアップ機能を追加できます',
    'exportData': 'ローカルデータを書き出す',
    'exportDataDescription': '履歴、現在の計時、アプリ設定をバックアップします',
    'importData': 'ローカルデータを読み込む',
    'importDataDescription': 'Stopwatch Log の JSON バックアップから復元します',
    'backupFile': 'Stopwatch Log バックアップ',
    'exportAction': 'エクスポート',
    'dataExported': 'ローカルデータを書き出しました',
    'dataExportFailed': '書き出しに失敗しました。保存先を確認してください',
    'confirmDataImport': 'バックアップを読み込みますか？',
    'importDataWarning': '読み込むと、現在の履歴、計時、アプリ設定がすべて置き換わります。この操作は元に戻せません。',
    'cancel': 'キャンセル',
    'replaceData': 'データを置き換える',
    'dataImported': '{sessions} 件のセッションと {points} 件のポイントを読み込みました',
    'invalidBackupFile': 'バックアップが無効か、未対応のバージョンです',
    'dataImportFailed': '読み込みに失敗しました。既存のデータは変更されていません',
    'stopTimerBeforeImport': '現在の計時を終了またはリセットしてから読み込んでください',
    'fontFile': 'フォントファイル',
    'importAction': 'インポート',
    'fontImported': 'フォントをインポートしました',
    'fontFileMissing': 'フォントファイルが見つかりません',
    'unsupportedFontFile': '.ttf、.otf、.ttc のみ対応しています',
    'fontPathRequired': 'フォントファイルを選択してください',
    'fontImportFailed': 'インポートに失敗しました。ファイルを確認してください',
    'importedLocalFont': 'ローカルフォントをインポート済み',
    'importFontTypes': '.ttf / .otf / .ttc をインポート',
    'importFont': 'フォントをインポート',
    'resetDisplay': '表示設定を初期値に戻す',
    'resetDefault': '初期値に戻す',
    'customFont': 'カスタムフォント',
    'segoeDescription': '軽く見やすい標準の数字フォント',
    'cascadiaDescription': 'コロン間隔が安定した等幅数字',
    'consolasDescription': '整列しやすい定番の等幅フォント',
    'bahnschriftDescription': 'フローティング表示向けの細身の数字',
    'customFontDescription': 'インポートしたローカルフォントを使用',
  },
};
