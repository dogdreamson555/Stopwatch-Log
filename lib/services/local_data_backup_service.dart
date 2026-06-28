import '../database/database.dart';
import '../models/local_data_backup.dart';

class LocalDataBackupService {
  final AppDatabase database;

  const LocalDataBackupService(this.database);

  Future<String> exportToJson() async {
    final backup = await database.createLocalDataBackup();
    return backup.toJsonString();
  }

  Future<LocalDataBackup> importFromJson(String source) async {
    final backup = LocalDataBackup.fromJsonString(source);
    await database.replaceLocalData(backup);
    return backup;
  }
}
