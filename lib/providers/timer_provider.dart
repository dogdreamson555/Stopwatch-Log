import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/timer_point.dart';
import '../models/timer_session.dart';
import 'session_archive_provider.dart';

const _uuid = Uuid();

/// 计时器运行状态
enum TimerStatus { idle, running, paused }

/// 计时器核心状态
class TimerState {
  final TimerStatus status;
  final Duration elapsed;
  final List<TimerPoint> points;
  final DateTime? sessionStartTime;
  final String sessionId;
  final bool showSeconds;
  final bool showHundredths;

  const TimerState({
    this.status = TimerStatus.idle,
    this.elapsed = Duration.zero,
    this.points = const [],
    this.sessionStartTime,
    this.sessionId = '',
    this.showSeconds = true,
    this.showHundredths = true,
  });

  TimerState copyWith({
    TimerStatus? status,
    Duration? elapsed,
    List<TimerPoint>? points,
    DateTime? sessionStartTime,
    String? sessionId,
    bool? showSeconds,
    bool? showHundredths,
  }) => TimerState(
    status: status ?? this.status,
    elapsed: elapsed ?? this.elapsed,
    points: points ?? this.points,
    sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    sessionId: sessionId ?? this.sessionId,
    showSeconds: showSeconds ?? this.showSeconds,
    showHundredths: showHundredths ?? this.showHundredths,
  );

  bool get isIdle => status == TimerStatus.idle;
  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isActive => status != TimerStatus.idle;

  Map<String, dynamic> toDraftJson(DateTime savedAt) => {
    'status': status.name,
    'elapsedMs': elapsed.inMilliseconds,
    'points': points.map((p) => p.toJson()).toList(),
    'sessionStartTime': sessionStartTime?.toIso8601String(),
    'sessionId': sessionId,
    'showSeconds': showSeconds,
    'showHundredths': showHundredths,
    'savedAt': savedAt.toIso8601String(),
  };

  factory TimerState.fromDraftJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? TimerStatus.idle.name;
    final status = TimerStatus.values.firstWhere(
      (v) => v.name == statusName,
      orElse: () => TimerStatus.idle,
    );
    final savedAtText = json['savedAt'] as String?;
    final savedAt = savedAtText == null ? null : DateTime.tryParse(savedAtText);
    var elapsed = Duration(milliseconds: json['elapsedMs'] as int? ?? 0);
    if (status == TimerStatus.running && savedAt != null) {
      final awayTime = DateTime.now().difference(savedAt);
      if (!awayTime.isNegative) {
        elapsed += awayTime;
      }
    }

    return TimerState(
      status: status,
      elapsed: elapsed,
      points: (json['points'] as List<dynamic>? ?? [])
          .map((p) => TimerPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      sessionStartTime: DateTime.tryParse(
        json['sessionStartTime'] as String? ?? '',
      ),
      sessionId: json['sessionId'] as String? ?? '',
      showSeconds: json['showSeconds'] as bool? ?? true,
      showHundredths: json['showHundredths'] as bool? ?? true,
    );
  }
}

/// 计时器 Notifier：管理所有计时逻辑
class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  late AppDatabase _db;
  Duration _baseElapsed = Duration.zero;
  DateTime? _lastPersistedAt;
  bool _restored = false;
  TimerState _latestState = const TimerState();
  int _persistVersion = 0;
  Future<void> _pendingPersist = Future.value();
  Future<void> _restoreFuture = Future.value();
  Future<TimerSession>? _pendingStop;

  Duration get _currentElapsed => _baseElapsed + _stopwatch.elapsed;

  @override
  TimerState build() {
    _db = ref.read(databaseProvider);
    _latestState = const TimerState();
    listenSelf((_, next) {
      _latestState = next;
    });
    ref.onDispose(() {
      _ticker?.cancel();
      unawaited(_persistLatestSnapshotOnDispose());
    });
    _restoreFuture = _restoreDraft();
    unawaited(_restoreFuture);
    return _latestState;
  }

  /// 启动计时（新会话）
  void start() {
    _baseElapsed = Duration.zero;
    _stopwatch
      ..reset()
      ..start();
    _startTicker();
    state = TimerState(
      status: TimerStatus.running,
      sessionId: _uuid.v4(),
      sessionStartTime: DateTime.now(),
    );
    unawaited(_persistDraft(force: true));
  }

  /// 暂停计时
  void pause() {
    _stopwatch.stop();
    _ticker?.cancel();
    state = state.copyWith(
      status: TimerStatus.paused,
      elapsed: _currentElapsed,
    );
    unawaited(_persistDraft(force: true));
  }

  /// 继续计时
  void resume() {
    _stopwatch.start();
    _startTicker();
    state = state.copyWith(status: TimerStatus.running);
    unawaited(_persistDraft(force: true));
  }

  /// 打点：在当前时刻记录一个点，附带可选备注
  void markPoint(String note) {
    final elapsed = _currentElapsed;
    final point = TimerPoint(elapsedAt: elapsed, note: note);
    state = state.copyWith(elapsed: elapsed, points: [...state.points, point]);
    unawaited(_persistDraft(force: true));
  }

  /// 结束计时并归档，归档成功后才清除当前状态。
  Future<TimerSession> stop() {
    final pending = _pendingStop;
    if (pending != null) return pending;

    final stopFuture = _stopAndArchive();
    _pendingStop = stopFuture;
    return stopFuture.whenComplete(() {
      if (_pendingStop == stopFuture) {
        _pendingStop = null;
      }
    });
  }

  Future<TimerSession> _stopAndArchive() async {
    _stopwatch.stop();
    _ticker?.cancel();
    final elapsed = _currentElapsed;
    final session = TimerSession(
      id: state.sessionId,
      date: state.sessionStartTime ?? DateTime.now(),
      totalElapsed: elapsed,
      points: state.points,
    );
    state = state.copyWith(status: TimerStatus.paused, elapsed: elapsed);
    await _persistDraft(force: true);

    await ref.read(sessionArchiveProvider.notifier).addSession(session);
    await _clearDraft();

    _baseElapsed = Duration.zero;
    _stopwatch.reset();
    state = const TimerState();
    return session;
  }

  /// 重置（等同丢弃当前会话）
  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    _baseElapsed = Duration.zero;
    _ticker?.cancel();
    state = const TimerState();
    unawaited(_clearDraft());
  }

  /// 切换是否显示秒
  void toggleSeconds() {
    state = state.copyWith(showSeconds: !state.showSeconds);
    unawaited(_persistDraft(force: true));
  }

  /// 切换是否显示毫秒
  void toggleHundredths() {
    state = state.copyWith(showHundredths: !state.showHundredths);
    unawaited(_persistDraft(force: true));
  }

  Future<void> persistNow() {
    if (state.isActive) {
      state = state.copyWith(elapsed: _currentElapsed);
    }
    return _persistDraft(force: true);
  }

  Future<bool> prepareForDataImport() async {
    await _restoreFuture;
    await _pendingPersist;
    return !state.isActive;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_stopwatch.isRunning) {
        state = state.copyWith(elapsed: _currentElapsed);
        unawaited(_persistDraft());
      }
    });
  }

  Future<void> _restoreDraft() async {
    if (_restored) return;
    _restored = true;

    final payload = await _db.loadCurrentTimerState();
    if (payload == null || payload.isEmpty) return;

    late final TimerState restored;
    try {
      restored = TimerState.fromDraftJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );
    } on Object {
      await _clearDraft();
      return;
    }
    if (!restored.isActive) return;

    state = restored;
    _baseElapsed = restored.elapsed;
    _stopwatch.reset();
    if (restored.isPaused) {
      _stopwatch.stop();
    } else {
      _stopwatch.start();
    }
    if (restored.isRunning) {
      _startTicker();
    }
    unawaited(_persistDraft(force: true));
  }

  Future<void> _persistDraft({bool force = false}) async {
    if (!state.isActive) return;
    final now = DateTime.now();
    if (!force &&
        _lastPersistedAt != null &&
        now.difference(_lastPersistedAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastPersistedAt = now;

    final version = ++_persistVersion;
    final payload = jsonEncode(state.toDraftJson(now));
    _pendingPersist = _pendingPersist.then((_) async {
      if (version != _persistVersion) return;
      await _db.saveCurrentTimerState(payload);
      if (version == _persistVersion) {
        _lastPersistedAt = now;
      }
    });
    await _pendingPersist;
  }

  Future<void> _persistLatestSnapshotOnDispose() async {
    final snapshot = _latestState;
    if (!snapshot.isActive) return;

    final now = DateTime.now();
    final version = ++_persistVersion;
    final payload = jsonEncode(
      snapshot.copyWith(elapsed: _currentElapsed).toDraftJson(now),
    );

    _pendingPersist = _pendingPersist.then((_) async {
      if (version != _persistVersion) return;
      await _db.saveCurrentTimerState(payload);
    });
    await _pendingPersist;
  }

  Future<void> _clearDraft() async {
    _persistVersion++;
    _pendingPersist = _pendingPersist.then((_) => _db.clearCurrentTimerState());
    await _pendingPersist;
  }
}

/// 全局计时器 Provider
final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);
