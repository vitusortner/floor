import 'package:analyzer/dart/element/element.dart';
import 'package:floor_generator/misc/annotations.dart';
import 'package:floor_generator/misc/extension/list_equality_extension.dart';
import 'package:floor_generator/value_object/field.dart';
import 'package:floor_generator/value_object/foreign_key.dart';
import 'package:floor_generator/value_object/index.dart';
import 'package:floor_generator/value_object/primary_key.dart';
import 'package:floor_generator/value_object/queryable.dart';

import 'fts.dart';

class Entity extends Queryable {
  final PrimaryKey primaryKey;
  final List<ForeignKey> foreignKeys;
  final List<Index> indices;
  final bool withoutRowid;
  final String valueMapping;
  final Fts fts;

  Entity(
    ClassElement classElement,
    String name,
    List<Field> fields,
    this.primaryKey,
    this.foreignKeys,
    this.indices,
    this.withoutRowid,
    String constructor,
    this.valueMapping,
    this.fts,
  ) : super(classElement, name, fields, constructor);

  @nonNull
  String getCreateTableStatement() {
    final databaseDefinition = fields.map((field) {
      final autoIncrement =
          primaryKey.fields.contains(field) && primaryKey.autoGenerateId;
      return field.getDatabaseDefinition(autoIncrement);
    }).toList();

    final foreignKeyDefinitions =
        foreignKeys.map((foreignKey) => foreignKey.getDefinition()).toList();
    databaseDefinition.addAll(foreignKeyDefinitions);

    final primaryKeyDefinition = _createPrimaryKeyDefinition();
    if (primaryKeyDefinition != null) {
      databaseDefinition.add(primaryKeyDefinition);
    }

    final withoutRowidClause = withoutRowid ? ' WITHOUT ROWID' : '';

    if (fts == null) {
      return 'CREATE TABLE IF NOT EXISTS `$name` (${databaseDefinition.join(', ')})$withoutRowidClause';
    } else {
      if (fts.tableCreateOption().isNotEmpty) {
        databaseDefinition.add('${fts.tableCreateOption()}');
      }
      return 'CREATE VIRTUAL TABLE IF NOT EXISTS `$name` ${fts.usingOption}(${databaseDefinition.join(', ')})';
    }
  }

  @nonNull
  String getDropTableStatement() {
    return 'DROP TABLE IF EXISTS `$name`';
  }

  @nullable
  String _createPrimaryKeyDefinition() {
    if (primaryKey.autoGenerateId) {
      return null;
    } else {
      final columns =
          primaryKey.fields.map((field) => '`${field.columnName}`').join(', ');
      return 'PRIMARY KEY ($columns)';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity &&
          runtimeType == other.runtimeType &&
          classElement == other.classElement &&
          name == other.name &&
          fields.equals(other.fields) &&
          primaryKey == other.primaryKey &&
          foreignKeys.equals(other.foreignKeys) &&
          indices.equals(other.indices) &&
          withoutRowid == other.withoutRowid &&
          constructor == other.constructor &&
          valueMapping == other.valueMapping;

  @override
  int get hashCode =>
      classElement.hashCode ^
      name.hashCode ^
      fields.hashCode ^
      primaryKey.hashCode ^
      foreignKeys.hashCode ^
      indices.hashCode ^
      constructor.hashCode ^
      withoutRowid.hashCode ^
      fts.hashCode ^
      valueMapping.hashCode;

  @override
  String toString() {
    return 'Entity{classElement: $classElement, name: $name, fields: $fields, primaryKey: $primaryKey, foreignKeys: $foreignKeys, indices: $indices, constructor: $constructor, withoutRowid: $withoutRowid, valueMapping: $valueMapping, fts: $fts}';
  }
}
