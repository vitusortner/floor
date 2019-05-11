import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:floor_generator/misc/constants.dart';
import 'package:floor_generator/processor/field_processor.dart';
import 'package:floor_generator/value_object/field.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  test('successfully process field', () async {
    final fieldElement = await _generateFieldElement('''
      @PrimaryKey()
      final int id;
    ''');

    final actual = FieldProcessor(fieldElement).process();

    const name = 'id';
    const columnName = 'id';
    const isNullable = true;
    const isPrimaryKey = true;
    const sqlType = SqlType.INTEGER;
    const readOnly = false;

    expect(
      actual,
      equals(Field(
        fieldElement,
        name,
        columnName,
        isNullable,
        readOnly,
        isPrimaryKey,
        sqlType,
      )),
    );
  });
}

Future<FieldElement> _generateFieldElement(final String field) async {
  final library = await resolveSource('''
      library test;
      
      import 'package:floor_annotation/floor_annotation.dart';
      
      class Foo {
        $field
      }
      ''', (resolver) async {
    return LibraryReader(await resolver.findLibraryByName('test'));
  });

  return library.classes.first.fields.first;
}
