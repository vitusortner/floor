import 'package:sqflite/sqlite_api.dart';

class AutoMigration {
  static Future<void> migrate(
      final Database database,
      List<String> createStatements
  ) async {
    /// Auto create new tables
    for (String statement in createStatements) {
      await database.execute(statement);
    }

    /// TODO: Auto check new columns
  }
}