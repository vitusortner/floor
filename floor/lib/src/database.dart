import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Extend this class to enable database functionality.
abstract class FloorDatabase {
  /// [StreamController] that is responsible for notifying listeners about changes
  /// in specific tables. It acts as an event bus.
  /// An event contains all changed tables, including those that were changed by
  /// foreign-key constraints.
  @protected
  late final StreamController<Set<String>> changeListener;

  /// Use this whenever you need direct access to the sqflite database.
  late final sqflite.DatabaseExecutor database;

  /// Closes the database.
  Future<void> close() async {
    await changeListener.close();

    final database = this.database;
    if (database is sqflite.Database && database.isOpen) {
      await database.close();
    }
  }
}
