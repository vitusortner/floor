abstract class AnnotationField {
  static const queryValue = 'value';
  static const primaryKeyAutoGenerate = 'autoGenerate';
  static const onConflict = 'onConflict';

  static const databaseVersion = 'version';
  static const databaseEntities = 'entities';
  static const fallbackToDestructiveMigration =
      'fallbackToDestructiveMigration';
  static const databaseViews = 'views';

  static const columnInfoName = 'name';
  static const columnInfoNullable = 'nullable';

  static const entityTableName = 'tableName';
  static const entityForeignKeys = 'foreignKeys';
  static const entityIndices = 'indices';
  static const entityPrimaryKeys = 'primaryKeys';
  static const entityWithoutRowid = 'withoutRowid';

  static const viewName = 'viewName';
  static const viewQuery = 'query';

  static const typeConverterValue = 'value';
}

abstract class ForeignKeyField {
  static const entity = 'entity';
  static const childColumns = 'childColumns';
  static const parentColumns = 'parentColumns';
  static const onUpdate = 'onUpdate';
  static const onDelete = 'onDelete';
}

abstract class Fts3Field {
  static const tokenizer = 'tokenizer';
  static const tokenizerArgs = 'tokenizerArgs';
}

abstract class Fts4Field {
  static const tokenizer = 'tokenizer';
  static const tokenizerArgs = 'tokenizerArgs';
}

abstract class IndexField {
  static const name = 'name';
  static const unique = 'unique';
  static const value = 'value';
}

abstract class SqlType {
  static const integer = 'INTEGER';
  static const text = 'TEXT';
  static const real = 'REAL';
  static const blob = 'BLOB';
}
