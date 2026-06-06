import 'timer_point.dart';

/// 一次完整的计时会话
class TimerSession {
  final String id;
  final DateTime date; // 会话日期
  final Duration totalElapsed; // 净总时长
  final List<TimerPoint> points; // 打点流
  final String summary; // 自我总结

  TimerSession({
    required this.id,
    required this.date,
    this.totalElapsed = Duration.zero,
    this.points = const [],
    this.summary = '',
  });

  TimerSession copyWith({
    String? id,
    DateTime? date,
    Duration? totalElapsed,
    List<TimerPoint>? points,
    String? summary,
  }) => TimerSession(
    id: id ?? this.id,
    date: date ?? this.date,
    totalElapsed: totalElapsed ?? this.totalElapsed,
    points: points ?? this.points,
    summary: summary ?? this.summary,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'totalElapsedMs': totalElapsed.inMilliseconds,
    'points': points.map((p) => p.toJson()).toList(),
    'summary': summary,
  };

  factory TimerSession.fromJson(Map<String, dynamic> json) => TimerSession(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    totalElapsed: Duration(milliseconds: json['totalElapsedMs'] as int),
    points: (json['points'] as List<dynamic>)
        .map((p) => TimerPoint.fromJson(p as Map<String, dynamic>))
        .toList(),
    summary: json['summary'] as String? ?? '',
  );
}
