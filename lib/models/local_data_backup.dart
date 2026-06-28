import 'dart:convert';

class LocalDataBackup {
  static const String applicationId = 'stopwatch_log';
  static const int currentFormatVersion = 1;

  final DateTime exportedAt;
  final List<LocalDataSession> sessions;
  final List<LocalDataPoint> points;
  final Map<String, String> settings;
  final Map<String, dynamic>? currentTimerState;

  const LocalDataBackup({
    required this.exportedAt,
    required this.sessions,
    required this.points,
    required this.settings,
    required this.currentTimerState,
  });

  factory LocalDataBackup.normalized({
    required DateTime exportedAt,
    required List<LocalDataSession> sessions,
    required List<LocalDataPoint> points,
    required Map<String, String> settings,
    required Map<String, dynamic>? currentTimerState,
  }) {
    final backup = LocalDataBackup(
      exportedAt: exportedAt,
      sessions: _recoverMissingPointSessions(sessions, points),
      points: points.toList(growable: false),
      settings: Map.unmodifiable(settings),
      currentTimerState: currentTimerState == null
          ? null
          : Map.unmodifiable(currentTimerState),
    );
    backup._validateRelations();
    return backup;
  }

  Map<String, dynamic> toJson() => {
    'application': applicationId,
    'formatVersion': currentFormatVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'sessions': sessions.map((session) => session.toJson()).toList(),
    'points': points.map((point) => point.toJson()).toList(),
    'settings': settings,
    'currentTimerState': currentTimerState,
  };

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  factory LocalDataBackup.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份文件根节点必须是对象');
    }
    return LocalDataBackup.fromJson(decoded);
  }

  factory LocalDataBackup.fromJson(Map<String, dynamic> json) {
    if (_requiredString(json, 'application') != applicationId) {
      throw const FormatException('不是 Stopwatch Log 备份文件');
    }

    final formatVersion = _requiredInt(json, 'formatVersion');
    if (formatVersion != currentFormatVersion) {
      throw FormatException('不支持的备份版本：$formatVersion');
    }

    final sessions = _requiredList(json, 'sessions')
        .map((value) => LocalDataSession.fromJson(_asMap(value, 'sessions')))
        .toList(growable: false);
    final points = _requiredList(json, 'points')
        .map((value) => LocalDataPoint.fromJson(_asMap(value, 'points')))
        .toList(growable: false);
    final settingsMap = _asMap(json['settings'], 'settings');
    final settings = <String, String>{};
    for (final entry in settingsMap.entries) {
      if (entry.value is! String) {
        throw FormatException('设置 ${entry.key} 的值必须是字符串');
      }
      settings[entry.key] = entry.value as String;
    }

    final rawCurrentTimerState = json['currentTimerState'];
    final currentTimerState = rawCurrentTimerState == null
        ? null
        : _asMap(rawCurrentTimerState, 'currentTimerState');
    if (currentTimerState != null) {
      _validateCurrentTimerState(currentTimerState);
    }

    final backup = LocalDataBackup.normalized(
      exportedAt: _requiredDateTime(json, 'exportedAt'),
      sessions: sessions,
      points: points,
      settings: Map.unmodifiable(settings),
      currentTimerState: currentTimerState == null
          ? null
          : Map.unmodifiable(currentTimerState),
    );
    return backup;
  }

  void _validateRelations() {
    final sessionIds = <String>{};
    for (final session in sessions) {
      if (!sessionIds.add(session.id)) {
        throw FormatException('会话 ID 重复：${session.id}');
      }
    }

    final pointIds = <String>{};
    for (final point in points) {
      if (!pointIds.add(point.id)) {
        throw FormatException('打点 ID 重复：${point.id}');
      }
      if (!sessionIds.contains(point.sessionId)) {
        throw FormatException('打点 ${point.id} 找不到所属会话');
      }
    }
  }
}

List<LocalDataSession> _recoverMissingPointSessions(
  List<LocalDataSession> sessions,
  List<LocalDataPoint> points,
) {
  final sessionIds = sessions.map((session) => session.id).toSet();
  final missingGroups = <String, List<LocalDataPoint>>{};
  for (final point in points) {
    if (sessionIds.contains(point.sessionId)) continue;
    (missingGroups[point.sessionId] ??= <LocalDataPoint>[]).add(point);
  }

  if (missingGroups.isEmpty) return sessions.toList(growable: false);

  final recoveredSessions = missingGroups.entries.map((entry) {
    final points = entry.value;
    var date = points.first.createdAt;
    var totalElapsedMs = points.first.elapsedAtMs;
    for (final point in points.skip(1)) {
      if (point.createdAt.isBefore(date)) date = point.createdAt;
      if (point.elapsedAtMs > totalElapsedMs) {
        totalElapsedMs = point.elapsedAtMs;
      }
    }
    return LocalDataSession(
      id: entry.key,
      date: date,
      totalElapsedMs: totalElapsedMs,
      summary: '',
    );
  });

  return [...sessions, ...recoveredSessions];
}

class LocalDataSession {
  final String id;
  final DateTime date;
  final int totalElapsedMs;
  final String summary;

  const LocalDataSession({
    required this.id,
    required this.date,
    required this.totalElapsedMs,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'totalElapsedMs': totalElapsedMs,
    'summary': summary,
  };

  factory LocalDataSession.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    final totalElapsedMs = _requiredInt(json, 'totalElapsedMs');
    if (id.isEmpty) throw const FormatException('会话 ID 不能为空');
    if (totalElapsedMs < 0) {
      throw const FormatException('会话时长不能为负数');
    }

    return LocalDataSession(
      id: id,
      date: _requiredDateTime(json, 'date'),
      totalElapsedMs: totalElapsedMs,
      summary: _optionalString(json, 'summary') ?? '',
    );
  }
}

class LocalDataPoint {
  final String id;
  final String sessionId;
  final int elapsedAtMs;
  final DateTime createdAt;
  final String note;

  const LocalDataPoint({
    required this.id,
    required this.sessionId,
    required this.elapsedAtMs,
    required this.createdAt,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'elapsedAtMs': elapsedAtMs,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory LocalDataPoint.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    final sessionId = _requiredString(json, 'sessionId');
    final elapsedAtMs = _requiredInt(json, 'elapsedAtMs');
    if (id.isEmpty) throw const FormatException('打点 ID 不能为空');
    if (sessionId.isEmpty) throw const FormatException('打点所属会话不能为空');
    if (elapsedAtMs < 0) throw const FormatException('打点时间不能为负数');

    return LocalDataPoint(
      id: id,
      sessionId: sessionId,
      elapsedAtMs: elapsedAtMs,
      createdAt: _requiredDateTime(json, 'createdAt'),
      note: _optionalString(json, 'note') ?? '',
    );
  }
}

void _validateCurrentTimerState(Map<String, dynamic> json) {
  final status = _requiredString(json, 'status');
  if (!const {'idle', 'running', 'paused'}.contains(status)) {
    throw const FormatException('当前计时状态无效');
  }

  if (_requiredInt(json, 'elapsedMs') < 0) {
    throw const FormatException('当前计时时长不能为负数');
  }
  _requiredString(json, 'sessionId');
  _requiredBool(json, 'showSeconds');
  _requiredBool(json, 'showHundredths');
  _requiredDateTime(json, 'savedAt');

  final sessionStartTime = json['sessionStartTime'];
  if (sessionStartTime != null) {
    if (sessionStartTime is! String ||
        DateTime.tryParse(sessionStartTime) == null) {
      throw const FormatException('当前计时开始时间无效');
    }
  }

  for (final value in _requiredList(json, 'points')) {
    final point = _asMap(value, 'currentTimerState.points');
    final id = _requiredString(point, 'id');
    if (id.isEmpty) throw const FormatException('当前计时打点 ID 不能为空');
    if (_requiredInt(point, 'elapsedAtMs') < 0) {
      throw const FormatException('当前计时打点时间不能为负数');
    }
    _requiredDateTime(point, 'createdAt');
    _optionalString(point, 'note');
  }
}

Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('$field 必须是对象');
  }

  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$field 包含非字符串键');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<dynamic> _requiredList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List<dynamic>) {
    throw FormatException('$key 必须是数组');
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key 必须是字符串');
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key 必须是字符串');
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key 必须是整数');
  return value;
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key 必须是布尔值');
  return value;
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('$key 不是有效日期');
  return parsed;
}
