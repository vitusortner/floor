import 'package:floor_annotation/floor_annotation.dart' show ForeignKeyAction;
import 'package:floor_generator/misc/foreign_key_map.dart';
import 'package:floor_generator/value_object/entity.dart';
import 'package:floor_generator/value_object/field.dart';
import 'package:floor_generator/value_object/foreign_key.dart';
import 'package:floor_generator/value_object/primary_key.dart';
import 'package:test/test.dart';

import '../fakes.dart';

void main() {
  group('Update', () {
    test('empty map affects nothing else', () {
      final tested = ForeignKeyMap.fromEntities([]);
      final entity = getFakeEntityWithFK('Person', []);

      expect(tested.getAffectedByUpdate(entity), equals({entity}));
    });
    test('no foreign keys affects nothing else', () {
      final entity = getFakeEntityWithFK('Person', []);

      final tested = ForeignKeyMap.fromEntities([entity]);

      expect(tested.getAffectedByUpdate(entity), equals({entity}));
    });
    test('unrelated foreign key affects nothing else', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('NotParent', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByUpdate(parent), equals({parent}));
    });
    test('foreign key with restrict affects nothing else', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByUpdate(parent), equals({parent}));
    });
    test('foreign key with noAction affects nothing else', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.noAction,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByUpdate(parent), equals({parent}));
    });
    test('foreign key with cascade but wrong columns affects nothing else', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByUpdate(parent, {'col2'}), equals({parent}));
    });
    test('foreign key with cascade affects other entity', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByUpdate(parent), equals({parent, child}));
    });
    test(
        'foreign key with cascade affects other entity with overlapping columns',
        () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1', 'col2'], ['col1', 'col2'],
            ForeignKeyAction.cascade, ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByUpdate(parent, {'col1', 'col3'}),
          equals({parent, child}));
    });
    test('foreign key with cascade affects other entities', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(
          tested.getAffectedByUpdate(parent), equals({parent, child, child2}));
    });
    test('foreign key affects other entities transitively', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Child1', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(
          tested.getAffectedByUpdate(parent), equals({parent, child, child2}));
    });
    test('foreign key does not affect other entities without matching columns',
        () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);
      // will not be affected by changes to parent because only col1 gets changed in Child1, but col2 is referenced
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Child1', ['col2'], ['col2'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(tested.getAffectedByUpdate(parent), equals({parent, child}));
    });
  });
  group('Delete', () {
    test('empty map affects nothing else', () {
      final tested = ForeignKeyMap.fromEntities([]);
      final entity = getFakeEntityWithFK('Person', []);

      expect(tested.getAffectedByDelete(entity), equals({entity}));
    });
    test('no foreign keys affects nothing else', () {
      final entity = getFakeEntityWithFK('Person', []);

      final tested = ForeignKeyMap.fromEntities([entity]);

      expect(tested.getAffectedByDelete(entity), equals({entity}));
    });
    test('unrelated foreign key affects nothing else', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('NotParent', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.cascade)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByDelete(parent), equals({parent}));
    });
    test('foreign key with restrict affects nothing else', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByDelete(parent), equals({parent}));
    });
    test('foreign key with noAction affects nothing else', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.noAction)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByDelete(parent), equals({parent}));
    });
    test('foreign key with cascade affects other entity', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.cascade)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByDelete(parent), equals({parent, child}));
    });
    test('foreign key with setNull affects other entity', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.setNull)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child]);

      expect(tested.getAffectedByDelete(parent), equals({parent, child}));
    });
    test('foreign key with cascade affects other entities', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.cascade)
      ]);
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.cascade)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(
          tested.getAffectedByDelete(parent), equals({parent, child, child2}));
    });
    test('foreign key with setDefault affects other entities', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.setDefault)
      ]);
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.setDefault)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(
          tested.getAffectedByDelete(parent), equals({parent, child, child2}));
    });
    test('foreign key with cascade affects other entities transitively', () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.cascade)
      ]);
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Child1', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.cascade)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(
          tested.getAffectedByDelete(parent), equals({parent, child, child2}));
    });
    test(
        'foreign key with cascade and setNull affects other entities transitively',
        () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.cascade)
      ]);
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Child1', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.setNull)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(
          tested.getAffectedByDelete(parent), equals({parent, child, child2}));
    });
    test(
        'foreign key with setNull and onUpdate:cascade affects other entities transitively if columns match',
        () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.setNull)
      ]);
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Child1', ['col1'], ['col1'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(
          tested.getAffectedByDelete(parent), equals({parent, child, child2}));
    });
    test('foreign key does not affect other entities without matching columns',
        () {
      final parent = getFakeEntityWithFK('Parent', []);
      final child = getFakeEntityWithFK('Child1', [
        ForeignKey('Parent', ['col1'], ['col1'], ForeignKeyAction.restrict,
            ForeignKeyAction.setDefault)
      ]);
      // will not be affected by changes to parent because only col1 gets changed in Child1, but col2 is referenced
      final child2 = getFakeEntityWithFK('Child2', [
        ForeignKey('Child1', ['col2'], ['col2'], ForeignKeyAction.cascade,
            ForeignKeyAction.restrict)
      ]);

      final tested = ForeignKeyMap.fromEntities([parent, child, child2]);

      expect(tested.getAffectedByDelete(parent), equals({parent, child}));
    });
  });
}

Entity getFakeEntityWithFK(String name, List<ForeignKey> keys) {
  final fields = ['col1', 'col2', 'col3', 'col4']
      .map((name) => Field(FakeFieldElement(), '', name, false, 'TEXT', null))
      .toList();

  return Entity(FakeClassElement(), name, fields, PrimaryKey([], true), keys,
      [], false, '', '', null);
}
