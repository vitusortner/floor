import 'package:meta/meta.dart';

/// Marks a class as a FloorDatabase.
class Database {
  /// The database version.
  final int version;

  /// The entities the database manages.
  final List<Type> entities;

  /// The views the database manages.
  final List<Type> views;

  //Allow to recreate the databse if user does not want to write migration on upgradation
  final bool fallbackToDestructiveMigration;

  /// Marks a class as a FloorDatabase.
  const Database({
    @required this.version,
    @required this.entities,
    this.fallbackToDestructiveMigration = false,
    this.views = const [],
  });
}
