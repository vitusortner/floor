import 'package:analyzer/dart/element/element.dart';
import 'package:dartx/dartx.dart';
import 'package:floor_annotation/floor_annotation.dart' as annotations;
import 'package:floor_generator/misc/annotations.dart';
import 'package:floor_generator/misc/constants.dart';
import 'package:floor_generator/misc/extension/set_extension.dart';
import 'package:floor_generator/misc/extension/type_converter_element_extension.dart';
import 'package:floor_generator/misc/type_utils.dart';
import 'package:floor_generator/processor/dao_processor.dart';
import 'package:floor_generator/processor/entity_processor.dart';
import 'package:floor_generator/processor/error/database_processor_error.dart';
import 'package:floor_generator/processor/processor.dart';
import 'package:floor_generator/processor/view_processor.dart';
import 'package:floor_generator/value_object/dao_getter.dart';
import 'package:floor_generator/value_object/database.dart';
import 'package:floor_generator/value_object/entity.dart';
import 'package:floor_generator/value_object/queryable.dart';
import 'package:floor_generator/value_object/type_converter.dart';
import 'package:floor_generator/value_object/view.dart';

class DatabaseProcessor extends Processor<Database> {
  final DatabaseProcessorError _processorError;

  final ClassElement _classElement;

  DatabaseProcessor(final ClassElement classElement)
      : assert(classElement != null),
        _classElement = classElement,
        _processorError = DatabaseProcessorError(classElement);

  @nonNull
  @override
  Database process() {
    final databaseName = _classElement.displayName;
    final databaseTypeConverters =
        _classElement.getTypeConverters(TypeConverterScope.database);
    final entities = _getEntities(_classElement, databaseTypeConverters);
    final views = _getViews(_classElement, databaseTypeConverters);
    final daoGetters = _getDaoGetters(
      databaseName,
      entities,
      views,
      databaseTypeConverters,
    );
    final version = _getDatabaseVersion();
    final allTypeConverters = _getAllTypeConverters(
      daoGetters,
      [...entities, ...views],
    );
    final bool isFallToDestruction = _getFallBackToDestruction();

    return Database(
      _classElement,
      databaseName,
      entities,
      views,
      daoGetters,
      version,
      databaseTypeConverters,
      isFallToDestruction,
      allTypeConverters,
    );
  }

  @nonNull
  int _getDatabaseVersion() {
    final version = _classElement
        .getAnnotation(annotations.Database)
        .getField(AnnotationField.databaseVersion)
        ?.toIntValue();

    if (version == null) throw _processorError.versionIsMissing;
    if (version < 1) throw _processorError.versionIsBelowOne;

    return version;
  }

  @nonNull
  bool _getFallBackToDestruction() {
    final isDestructive = _classElement
        .getAnnotation(annotations.Database)
        .getField(AnnotationField.fallbackToDestructiveMigration)
        ?.toBoolValue();

    return isDestructive;
  }

  @nonNull
  List<DaoGetter> _getDaoGetters(
    final String databaseName,
    final List<Entity> entities,
    final List<View> views,
    final Set<TypeConverter> typeConverters,
  ) {
    return _classElement.fields.where(_isDao).map((field) {
      final classElement = field.type.element as ClassElement;
      final name = field.displayName;

      final dao = DaoProcessor(
        classElement,
        name,
        databaseName,
        entities,
        views,
        typeConverters,
      ).process();

      return DaoGetter(field, name, dao);
    }).toList();
  }

  @nonNull
  bool _isDao(final FieldElement fieldElement) {
    final element = fieldElement.type.element;
    return element is ClassElement ? _isDaoClass(element) : false;
  }

  @nonNull
  bool _isDaoClass(final ClassElement classElement) {
    return classElement.hasAnnotation(annotations.dao.runtimeType) &&
        classElement.isAbstract;
  }

  @nonNull
  List<Entity> _getEntities(
    final ClassElement databaseClassElement,
    final Set<TypeConverter> typeConverters,
  ) {
    final entities = _classElement
        .getAnnotation(annotations.Database)
        .getField(AnnotationField.databaseEntities)
        ?.toListValue()
        ?.map((object) => object.toTypeValue().element)
        ?.whereType<ClassElement>()
        ?.where(_isEntity)
        ?.map((classElement) => EntityProcessor(
              classElement,
              typeConverters,
            ).process())
        ?.toList();

    if (entities == null || entities.isEmpty) {
      throw _processorError.noEntitiesDefined;
    }

    return entities;
  }

  @nonNull
  List<View> _getViews(
    final ClassElement databaseClassElement,
    final Set<TypeConverter> typeConverters,
  ) {
    return _classElement
            .getAnnotation(annotations.Database)
            .getField(AnnotationField.databaseViews)
            ?.toListValue()
            ?.map((object) => object.toTypeValue().element)
            ?.whereType<ClassElement>()
            ?.where(_isView)
            ?.map((classElement) => ViewProcessor(
                  classElement,
                  typeConverters,
                ).process())
            ?.toList() ??
        [];
  }

  @nonNull
  Set<TypeConverter> _getAllTypeConverters(
    final List<DaoGetter> daoGetters,
    final List<Queryable> queryables,
  ) {
    // DAO query methods have access to all type converters
    final daoQueryMethodTypeConverters = daoGetters
        .expand((daoGetter) => daoGetter.dao.queryMethods)
        .expand((queryMethod) => queryMethod.typeConverters)
        .toSet();

    // but when no query methods are defined, we need to collect them differently
    final daoTypeConverters =
        daoGetters.expand((daoGetter) => daoGetter.dao.typeConverters).toSet();

    final fieldTypeConverters = queryables
        .expand((queryable) => queryable.fields)
        .mapNotNull((field) => field.typeConverter)
        .toSet();

    return daoQueryMethodTypeConverters +
        daoTypeConverters +
        fieldTypeConverters;
  }

  @nonNull
  bool _isEntity(final ClassElement classElement) {
    return classElement.hasAnnotation(annotations.Entity) &&
        !classElement.isAbstract;
  }

  @nonNull
  bool _isView(final ClassElement classElement) {
    return classElement.hasAnnotation(annotations.DatabaseView) &&
        !classElement.isAbstract;
  }
}
