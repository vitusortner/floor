import 'dart:async';

import 'package:sqflite/sqflite.dart';

/// This class knows how to execute database queries.
class QueryAdapter {
  final DatabaseExecutor _database;
  final StreamController<Set<String>>? _changeListener;

  QueryAdapter(
    final DatabaseExecutor database, [
    final StreamController<Set<String>>? changeListener,
  ])  : _database = database,
        _changeListener = changeListener;

  /// Executes a SQLite query that may return a single value.
  Future<T?> query<T>(
    final String sql, {
    final List<Object>? arguments,
    required final T Function(Map<String, Object?>) mapper,
  }) async {
    final rows = await _database.rawQuery(sql, arguments);

    if (rows.isEmpty) {
      return null;
    } else if (rows.length > 1) {
      throw StateError("Query returned more than one row for '$sql'");
    }

    return mapper(rows.first);
  }

  /// Executes a SQLite query that may return multiple values.
  Future<List<T>> queryList<T>(
    final String sql, {
    final List<Object>? arguments,
    required final T Function(Map<String, Object?>) mapper,
  }) async {
    final rows = await _database.rawQuery(sql, arguments);
    return rows.map((row) => mapper(row)).toList();
  }

  Future<void> queryNoReturn(
    final String sql, {
    final List<Object>? arguments,
  }) async {
    // TODO #94 differentiate between different query kinds (select, update, delete, insert)
    //  this enables to notify the observers
    //  also requires extracting the table name :(
    await _database.rawQuery(sql, arguments);
  }

  /// Executes a SQLite query that returns a stream of single query results
  /// or `null`.
  Stream<T?> queryStream<T>(
    final String sql, {
    final List<Object>? arguments,
    required final String queryableName,
    required final bool isView,
    required final T Function(Map<String, Object?>) mapper,
  }) {
    // ignore: close_sinks
    final changeListener = ArgumentError.checkNotNull(_changeListener);
    final controller = StreamController<T?>.broadcast();

    Future<void> executeQueryAndNotifyController() async {
      final result = await query(sql, arguments: arguments, mapper: mapper);
      controller.add(result);
    }

    controller.onListen = () async => executeQueryAndNotifyController();

    // listen on all updates if the stream is on a view, only listen to the
    // name of the table if the stream is on a entity.
    final subscription = changeListener.stream
        .where(
            (updatedTables) => isView || updatedTables.contains(queryableName))
        .listen(
          (_) async => executeQueryAndNotifyController(),
          onDone: () => controller.close(),
        );

    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }

  /// Executes a SQLite query that returns a stream of multiple query results.
  Stream<List<T>> queryListStream<T>(
    final String sql, {
    final List<Object>? arguments,
    required final String queryableName,
    required final bool isView,
    required final T Function(Map<String, Object?>) mapper,
  }) {
    // ignore: close_sinks
    final changeListener = ArgumentError.checkNotNull(_changeListener);
    final controller = StreamController<List<T>>.broadcast();

    Future<void> executeQueryAndNotifyController() async {
      final result = await queryList(sql, arguments: arguments, mapper: mapper);
      controller.add(result);
    }

    controller.onListen = () async => executeQueryAndNotifyController();

    // Views listen on all events, Entities only on events that changed the same entity.
    final subscription = changeListener.stream
        .where(
            (updatedTables) => isView || updatedTables.contains(queryableName))
        .listen(
          (_) async => executeQueryAndNotifyController(),
          onDone: () => controller.close(),
        );

    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }
}
