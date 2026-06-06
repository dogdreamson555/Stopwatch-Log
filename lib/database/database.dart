import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ============================================================
// 表定义
// ============================================================

/// 计时会话表
@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalElapsedMs => integer()();
  TextColumn get summary => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 打点记录表
@DataClassName('PointRow')
class Points extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().customConstraint(
    'NOT NULL REFERENCES sessions(id) ON DELETE CASCADE',
  )();
  IntColumn get elapsedAtMs => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// 数据库
// ============================================================

@DriftDatabase(tables: [Sessions, Points])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('''
        CREATE TABLE IF NOT EXISTS current_timer_state (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          payload TEXT NOT NULL
        )
      ''');
    },
  );

  // ---- 会话 CRUD ----

  /// 获取所有会话（按日期倒序）
  Future<List<SessionRow>> allSessions() {
    return (select(
      sessions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  /// 插入一个新会话
  Future<void> insertSession(SessionsCompanion session) {
    return into(sessions).insert(session);
  }

  /// 更新某个会话的总结
  Future<void> updateSummary(String id, String summary) {
    return (update(sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(summary: Value(summary)),
    );
  }

  /// 删除某个会话（级联删除其打点）
  Future<void> deleteSession(String id) {
    return transaction(() async {
      await (delete(points)..where((t) => t.sessionId.equals(id))).go();
      await (delete(sessions)..where((t) => t.id.equals(id))).go();
    });
  }

  // ---- 打点 CRUD ----

  /// 批量插入打点
  Future<void> insertPoints(List<PointsCompanion> rows) {
    return batch((b) => b.insertAll(points, rows));
  }

  /// 获取某会话的全部打点
  Future<List<PointRow>> pointsForSession(String sessionId) {
    return (select(points)..where((t) => t.sessionId.equals(sessionId))).get();
  }

  // ---- 当前计时草稿 ----

  /// 读取未结束的主界面状态。
  Future<String?> loadCurrentTimerState() async {
    await _ensureCurrentTimerStateTable();
    final row = await customSelect(
      'SELECT payload FROM current_timer_state WHERE id = 1',
    ).getSingleOrNull();
    return row?.read<String>('payload');
  }

  /// 保存未结束的主界面状态。
  Future<void> saveCurrentTimerState(String payload) async {
    await _ensureCurrentTimerStateTable();
    await customStatement(
      '''
      INSERT INTO current_timer_state (id, payload)
      VALUES (1, ?)
      ON CONFLICT(id) DO UPDATE SET payload = excluded.payload
      ''',
      [payload],
    );
  }

  /// 清空未结束的主界面状态。
  Future<void> clearCurrentTimerState() async {
    await _ensureCurrentTimerStateTable();
    await customStatement('DELETE FROM current_timer_state WHERE id = 1');
  }

  Future<void> _ensureCurrentTimerStateTable() {
    return customStatement('''
      CREATE TABLE IF NOT EXISTS current_timer_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        payload TEXT NOT NULL
      )
    ''');
  }
}

// ============================================================
// 数据库连接工厂
// ============================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsFolder = await getApplicationDocumentsDirectory();
    final dbFolder = Directory(p.join(documentsFolder.path, 'Stopwatch Log'));
    await dbFolder.create(recursive: true);

    final file = File(p.join(dbFolder.path, 'stopwatch_log.db'));
    await _migrateLegacyDatabaseIfNeeded(
      oldPath: p.join(documentsFolder.path, 'stopwatch_log.db'),
      newPath: file.path,
    );

    return NativeDatabase.createInBackground(file);
  });
}

Future<void> _migrateLegacyDatabaseIfNeeded({
  required String oldPath,
  required String newPath,
}) async {
  final oldFile = File(oldPath);
  final newFile = File(newPath);

  if (!await oldFile.exists() || await newFile.exists()) return;

  await oldFile.copy(newPath);
  for (final suffix in ['-wal', '-shm']) {
    final oldSidecar = File('$oldPath$suffix');
    if (await oldSidecar.exists()) {
      await oldSidecar.copy('$newPath$suffix');
    }
  }
}
