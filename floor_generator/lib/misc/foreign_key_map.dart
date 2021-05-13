import 'package:floor_annotation/floor_annotation.dart' show ForeignKeyAction;
import 'package:floor_generator/value_object/entity.dart';
import 'package:floor_generator/value_object/foreign_key.dart';
import 'package:floor_generator/misc/extension/foreign_key_action_extension.dart';

class ForeignKeyMap {
  final Map<String, Map<ForeignKey, Entity>> fkDependencies;

  ForeignKeyMap.fromEntities(Iterable<Entity> stuff)
      : fkDependencies = _generateFKMap(stuff);

  /// Determine the set of entities which could be altered if a row of [e] was updated.
  ///
  /// Traverses the given dependency map (Parent:[(ForeignKey:Child)]) and
  /// tries to figure out which entities an update of [e] could at most change.
  ///It excludes all children with a [ForeignKeyAction.noAction] and [ForeignKeyAction.restrict]
  /// and only looks further if the given child columns are itself part of another
  /// foreign key relationship.
  ///
  /// The returned set includes the given entity by default.
  Set<Entity> getAffectedByUpdate(final Entity e,
      [final Set<String>? columnsInput]) {
    final updatedColumns =
        columnsInput ?? e.fields.map((e) => e.columnName).toSet();
    return fkDependencies[e.name]
            ?.entries
            .where((element) => element.key.onUpdate.changesChildren())
            .where((element) => element.key.parentColumns
                .any((col) => updatedColumns.contains(col)))
            .expand((element) => getAffectedByUpdate(
                element.value, element.key.childColumns.toSet()))
            .followedBy([e]).toSet() ??
        {e};
  }

  /// Determine the set of entities which could be altered if a row of [e] was deleted.
  ///
  /// Traverses the given dependency map (Parent:[(ForeignKey:Child)]) and
  /// tries to figure out which entities an update of [e] could at most change.
  ///
  /// It excludes all children with a [ForeignKeyAction.noAction] and [ForeignKeyAction.restrict].
  /// It then distinguishes between [ForeignKeyAction.cascade], which deletes rows
  /// in the child entity, and [ForeignKeyAction.setNull]/[ForeignKeyAction.setDefault],
  /// which only update a row in the child entity. In the latter case, the
  /// exact columns are inspected.
  ///
  /// The returned set includes the given entity by default.
  Set<Entity> getAffectedByDelete(final Entity e) {
    return fkDependencies[e.name]
            ?.entries
            .where((element) => element.key.onDelete.changesChildren())
            .expand((element) {
          if (element.key.onDelete == ForeignKeyAction.cascade) {
            //if deletes are cascaded, check for entities affected by a deletion
            return getAffectedByDelete(element.value);
          } else {
            //if only default/null are replaced, check for entities affected by a update
            return getAffectedByUpdate(
                element.value, element.key.childColumns.toSet());
          }
        }).followedBy([e]).toSet() ??
        {e};
  }

  static Map<String, Map<ForeignKey, Entity>> _generateFKMap(
      Iterable<Entity> entities) {
    final reverseMap = <String, Map<ForeignKey, Entity>>{};
    for (final entity in entities) {
      for (final foreignKey in entity.foreignKeys) {
        final otherEntityName = foreignKey.parentName;
        reverseMap.update(
          otherEntityName,
          (value) {
            value[foreignKey] = entity;
            return value;
          },
          ifAbsent: () => {foreignKey: entity},
        );
      }
    }
    return reverseMap;
  }
}
