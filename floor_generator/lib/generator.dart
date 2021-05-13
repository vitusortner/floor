import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:floor_annotation/floor_annotation.dart' as annotations;
import 'package:floor_generator/misc/foreign_key_map.dart';
import 'package:floor_generator/misc/extension/iterable_extension.dart';
import 'package:floor_generator/processor/database_processor.dart';
import 'package:floor_generator/value_object/database.dart';
import 'package:floor_generator/writer/dao_writer.dart';
import 'package:floor_generator/writer/database_builder_writer.dart';
import 'package:floor_generator/writer/database_writer.dart';
import 'package:floor_generator/writer/floor_writer.dart';
import 'package:floor_generator/writer/type_converter_field_writer.dart';
import 'package:source_gen/source_gen.dart';

/// Floor generator that produces the implementation of the persistence code.
class FloorGenerator extends GeneratorForAnnotation<annotations.Database> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    final Element element,
    final ConstantReader annotation,
    final BuildStep buildStep,
  ) {
    final database = _getDatabase(element);

    final databaseClass = DatabaseWriter(database).write();
    final fkDepMap = ForeignKeyMap.fromEntities(database.entities);
    final daoClasses = database.daoGetters
        .map((daoGetter) => daoGetter.dao)
        .map((dao) => DaoWriter(
              dao,
              database.streamEntities,
              database.hasViewStreams,
              fkDepMap,
            ).write());
    final distinctTypeConverterFields = database.allTypeConverters
        .distinctBy((element) => element.name)
        .map((typeConverter) =>
            TypeConverterFieldWriter(typeConverter.name).write());

    final library = Library((builder) {
      builder
        ..body.add(FloorWriter(database.name).write())
        ..body.add(DatabaseBuilderWriter(database.name).write())
        ..body.add(databaseClass)
        ..body.addAll(daoClasses);

      if (distinctTypeConverterFields.isNotEmpty) {
        builder
          ..body.add(const Code('// ignore_for_file: unused_element\n'))
          ..body.addAll(distinctTypeConverterFields);
      }
    });

    return library.accept(DartEmitter()).toString();
  }

  Database _getDatabase(final Element element) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'The element annotated with @Database is not a class.',
          element: element);
    }

    if (!element.isAbstract) {
      throw InvalidGenerationSourceError(
          'The database class has to be abstract.',
          element: element);
    }

    return DatabaseProcessor(element).process();
  }
}
