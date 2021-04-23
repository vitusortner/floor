import 'dart:async';

import 'package:floor/floor.dart';
import 'package:floor_annotation/floor_annotation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'bool_test.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bool tests', () {
    TestDatabase database;
    BoolDao boolDao;

    setUp(() async {
      database = await $FloorTestDatabase.inMemoryDatabaseBuilder().build();
      boolDao = database.boolDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('find by nonNull true', () async {
      final obj = BooleanClass(true, nullable: false, nonnullable: true);
      await boolDao.insertBoolC(obj);

      final actual = await boolDao.findWithNonNullable(true);
      expect(actual, equals(obj));
    });

    test('find by nonNull false and convert null boolean', () async {
      final obj = BooleanClass(true, nullable: null, nonnullable: false);
      await boolDao.insertBoolC(obj);

      final actual = await boolDao.findWithNonNullable(false);
      expect(actual, equals(obj));
    });

    test('find by nullable null', () async {
      final obj = BooleanClass(true, nullable: null, nonnullable: true);
      await boolDao.insertBoolC(obj);

      final actual2 = await boolDao.findWithNullableBeingNull();
      expect(actual2, equals(obj));
    });

    test('find by nullable true', () async {
      final obj = BooleanClass(true, nullable: true, nonnullable: true);
      await boolDao.insertBoolC(obj);

      final actual = await boolDao.findWithNullable(true);
      expect(actual, equals(obj));
    });

    test('find by nullable false', () async {
      final obj = BooleanClass(true, nullable: false, nonnullable: true);
      await boolDao.insertBoolC(obj);

      final actual = await boolDao.findWithNullable(false);
      expect(actual, equals(obj));
    });
  });
}

@entity
class BooleanClass {
  @primaryKey
  final bool id;

  @ColumnInfo(nullable: true)
  final bool nullable;

  @ColumnInfo(nullable: false)
  final bool nonnullable;

  BooleanClass(this.id, {this.nullable, this.nonnullable});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BooleanClass &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nullable == other.nullable &&
          nonnullable == other.nonnullable;

  @override
  int get hashCode => id.hashCode ^ nullable.hashCode ^ nonnullable.hashCode;

  @override
  String toString() {
    return 'BooleanClass{id: $id, nullable: $nullable, nonnullable: $nonnullable}';
  }
}

@Database(version: 1, entities: [BooleanClass])
abstract class TestDatabase extends FloorDatabase {
  BoolDao get boolDao;
}

@dao
abstract class BoolDao {
  @Query('SELECT * FROM BooleanClass where nonnullable = :val')
  Future<BooleanClass> findWithNonNullable(bool val);

  @Query('SELECT * FROM BooleanClass where nullable = :val')
  Future<BooleanClass> findWithNullable(bool val);

  @Query('SELECT * FROM BooleanClass where nullable is null')
  Future<BooleanClass> findWithNullableBeingNull();

  @insert
  Future<void> insertBoolC(BooleanClass person);
}
