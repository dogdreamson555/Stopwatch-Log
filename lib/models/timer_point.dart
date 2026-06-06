import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 计时过程中打下的一个"时间点"，关联一段即时文字备注
class TimerPoint {
  final String id;
  final Duration elapsedAt; // 打点时刻的累计用时
  final DateTime createdAt; // 打点的实际时间戳
  final String note; // 即时备注文字

  TimerPoint({
    String? id,
    required this.elapsedAt,
    DateTime? createdAt,
    this.note = '',
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'elapsedAtMs': elapsedAt.inMilliseconds,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory TimerPoint.fromJson(Map<String, dynamic> json) => TimerPoint(
    id: json['id'] as String,
    elapsedAt: Duration(milliseconds: json['elapsedAtMs'] as int),
    createdAt: DateTime.parse(json['createdAt'] as String),
    note: json['note'] as String? ?? '',
  );

  @override
  String toString() => 'TimerPoint($elapsedAt, "$note")';
}
