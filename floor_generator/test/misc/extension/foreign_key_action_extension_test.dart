import 'package:floor_annotation/floor_annotation.dart' as annotations;
import 'package:floor_generator/misc/extension/foreign_key_action_extension.dart';
import 'package:test/test.dart';

void main() {
  group('foreign key action strings', () {
    test('NO ACTION', () {
      final actual = annotations.ForeignKeyAction.noAction.toSql();
      expect(actual, equals('NO ACTION'));
    });

    test('RESTRICT', () {
      final actual = annotations.ForeignKeyAction.restrict.toSql();
      expect(actual, equals('RESTRICT'));
    });

    test('SET NULL', () {
      final actual = annotations.ForeignKeyAction.setNull.toSql();
      expect(actual, equals('SET NULL'));
    });

    test('SET DEFAULT', () {
      final actual = annotations.ForeignKeyAction.setDefault.toSql();
      expect(actual, equals('SET DEFAULT'));
    });

    test('CASCADE', () {
      final actual = annotations.ForeignKeyAction.cascade.toSql();
      expect(actual, equals('CASCADE'));
    });
  });
  group('foreign key changesChild', () {
    test('NO ACTION', () {
      expect(annotations.ForeignKeyAction.noAction.changesChildren(), isFalse);
    });

    test('RESTRICT', () {
      expect(annotations.ForeignKeyAction.restrict.changesChildren(), isFalse);
    });

    test('SET NULL', () {
      expect(annotations.ForeignKeyAction.setNull.changesChildren(), isTrue);
    });

    test('SET DEFAULT', () {
      expect(annotations.ForeignKeyAction.setDefault.changesChildren(), isTrue);
    });

    test('CASCADE', () {
      expect(annotations.ForeignKeyAction.cascade.changesChildren(), isTrue);
    });
  });
}
