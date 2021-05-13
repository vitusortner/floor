import 'dart:async';

import 'package:floor/src/extension/on_conflict_strategy_extensions.dart';
import 'package:floor_annotation/floor_annotation.dart';
import 'package:sqflite/sqlite_api.dart';

class InsertionAdapter<T> {
  final DatabaseExecutor _database;
  final String _entityName;
  final Map<String, Object?> Function(T) _valueMapper;
  final void Function(bool) _changeHandler;

  InsertionAdapter(
    final DatabaseExecutor database,
    final String entityName,
    final Map<String, Object?> Function(T) valueMapper, [
    final void Function(bool)? changeHandler,
  ])  : assert(entityName.isNotEmpty),
        _database = database,
        _entityName = entityName,
        _valueMapper = valueMapper,
        _changeHandler = changeHandler ?? ((bool isReplace) {/* do nothing */});

  Future<void> insert(
    final T item,
    final OnConflictStrategy onConflictStrategy,
  ) async {
    await _insert(item, onConflictStrategy);
  }

  Future<void> insertList(
    final List<T> items,
    final OnConflictStrategy onConflictStrategy,
  ) async {
    if (items.isEmpty) return;
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(
        _entityName,
        _valueMapper(item),
        conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
      );
    }
    await batch.commit(noResult: true);
    _changeHandler(onConflictStrategy == OnConflictStrategy.replace);
  }

  Future<int> insertAndReturnId(
    final T item,
    final OnConflictStrategy onConflictStrategy,
  ) {
    return _insert(item, onConflictStrategy);
  }

  Future<List<int>> insertListAndReturnIds(
    final List<T> items,
    final OnConflictStrategy onConflictStrategy,
  ) async {
    if (items.isEmpty) return [];
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(
        _entityName,
        _valueMapper(item),
        conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
      );
    }
    final result = (await batch.commit(noResult: false)).cast<int>();
    if (result.isNotEmpty)
      _changeHandler(onConflictStrategy == OnConflictStrategy.replace);
    return result;
  }

  Future<int> _insert(
    final T item,
    final OnConflictStrategy onConflictStrategy,
  ) async {
    final result = await _database.insert(
      _entityName,
      _valueMapper(item),
      conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
    );
    if (result != 0)
      _changeHandler(onConflictStrategy == OnConflictStrategy.replace);
    return result;
  }
}
