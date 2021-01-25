import 'package:code_builder/code_builder.dart';
import 'package:floor_generator/misc/annotation_expression.dart';
import 'package:floor_generator/misc/annotations.dart';
import 'package:floor_generator/value_object/database.dart';
import 'package:floor_generator/value_object/entity.dart';
import 'package:floor_generator/writer/writer.dart';

/// Takes care of generating the database implementation.
class DatabaseWriter implements Writer {
  final Database database;

  DatabaseWriter(final this.database);

  @nonNull
  @override
  Class write() {
    return _generateDatabaseImplementation(database);
  }

  @nonNull
  Class _generateDatabaseImplementation(final Database database) {
    final databaseName = database.name;

    return Class((builder) => builder
      ..name = '_\$$databaseName'
      ..extend = refer(databaseName)
      ..methods.add(_generateOpenMethod(database))
      ..methods.addAll(_generateDaoGetters(database))
      ..fields.addAll(_generateDaoInstances(database))
      ..constructors.add(_generateConstructor()));
  }

  @nonNull
  Constructor _generateConstructor() {
    return Constructor((builder) {
      final parameter = Parameter((builder) => builder
        ..name = 'listener'
        ..type = refer('StreamController<String>'));

      return builder
        ..body = const Code(
          'changeListener = listener ?? StreamController<String>.broadcast();',
        )
        ..optionalParameters.add(parameter);
    });
  }

  @nonNull
  List<Method> _generateDaoGetters(final Database database) {
    return database.daoGetters.map((daoGetter) {
      final daoGetterName = daoGetter.name;
      final daoTypeName = daoGetter.dao.classElement.displayName;

      return Method((builder) => builder
        ..annotations.add(overrideAnnotationExpression)
        ..type = MethodType.getter
        ..returns = refer(daoTypeName)
        ..name = daoGetterName
        ..body = Code(
            'return _${daoGetterName}Instance ??= _\$$daoTypeName(database, changeListener);'));
    }).toList();
  }

  @nonNull
  List<Field> _generateDaoInstances(final Database database) {
    return database.daoGetters.map((daoGetter) {
      final daoGetterName = daoGetter.name;
      final daoTypeName = daoGetter.dao.classElement.displayName;

      return Field((builder) => builder
        ..type = refer(daoTypeName)
        ..name = '_${daoGetterName}Instance');
    }).toList();
  }

  @nonNull
  Method _generateOpenMethod(final Database database) {
    final createTableStatements =
        _generateCreateTableSqlStatements(database.entities)
            .map((statement) => "await database.execute('$statement');")
            .join('\n');
    final createIndexStatements = database.entities
        .map((entity) => entity.indices.map((index) => index.createQuery()))
        .expand((statements) => statements)
        .map((statement) => "await database.execute('$statement');")
        .join('\n');
    final createViewStatements = database.views
        .map((view) => view.getCreateViewStatement())
        .map((statement) => "await database.execute('''$statement''');")
        .join('\n');

    final pathParameter = Parameter((builder) => builder
      ..name = 'path'
      ..type = refer('String'));
    final migrationsParameter = Parameter((builder) => builder
      ..name = 'migrations'
      ..type = refer('List<Migration>'));
    final callbackParameter = Parameter((builder) => builder
      ..name = 'callback'
      ..type = refer('Callback'));

    return Method((builder) => builder
      ..name = 'open'
      ..returns = refer('Future<sqflite.Database>')
      ..modifier = MethodModifier.async
      ..requiredParameters.addAll([pathParameter, migrationsParameter])
      ..optionalParameters.add(callbackParameter)
      ..body = Code('''
          final databaseOptions = sqflite.OpenDatabaseOptions(
            version: ${database.version},
            onConfigure: (database) async {
              await database.execute('PRAGMA foreign_keys = ON');
            },
            onOpen: (database) async {
              await callback?.onOpen?.call(database);
            },
            onUpgrade: (database, startVersion, endVersion) async {
              ${_getOnUpgradeString(database, createTableStatements, createIndexStatements, createViewStatements)}
            },
            onCreate: (database, version) async {
              $createTableStatements
              $createIndexStatements
              $createViewStatements

              await callback?.onCreate?.call(database, version);
            },
          );
          return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
          '''));
  }

  @nonNull
  String _getOnUpgradeString(Database database, String createTable,
      String createIndex, String createView) {
    if (database.fallbackToDestructiveMigration) {
      final dropTableStatements =
          _generateDropTableSqlStatements(database.entities)
              .map((statement) => "await database.execute('$statement');")
              .join('\n');

      return '''
              $dropTableStatements
              
              $createTable
              $createIndex
              $createView
              
              await callback?.onCreate?.call(database, endVersion);
          ''';
    } else {
      return '''
            await MigrationAdapter.runMigrations(database, startVersion, endVersion, migrations);

            await callback?.onUpgrade?.call(database, startVersion, endVersion);
          ''';
    }
  }

  @nonNull
  List<String> _generateDropTableSqlStatements(final List<Entity> entities) {
    return entities.map((entity) => entity.getDropTableStatement()).toList();
  }

  @nonNull
  List<String> _generateCreateTableSqlStatements(final List<Entity> entities) {
    return entities.map((entity) => entity.getCreateTableStatement()).toList();
  }
}
