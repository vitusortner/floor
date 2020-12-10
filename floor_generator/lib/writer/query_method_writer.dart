import 'dart:core';

import 'package:code_builder/code_builder.dart';
import 'package:dartx/dartx.dart';
import 'package:floor_generator/misc/annotation_expression.dart';
import 'package:floor_generator/misc/annotations.dart';
import 'package:floor_generator/misc/extension/type_converters_extension.dart';
import 'package:floor_generator/misc/type_utils.dart';
import 'package:floor_generator/value_object/query_method.dart';
import 'package:floor_generator/value_object/view.dart';
import 'package:floor_generator/writer/writer.dart';

class QueryMethodWriter implements Writer {
  final QueryMethod _queryMethod;

  QueryMethodWriter(final QueryMethod queryMethod)
      : assert(queryMethod != null),
        _queryMethod = queryMethod;

  @override
  Method write() {
    final builder = MethodBuilder()
      ..annotations.add(overrideAnnotationExpression)
      ..returns = refer(_queryMethod.rawReturnType.getDisplayString(
        withNullability: false,
      ))
      ..name = _queryMethod.name
      ..requiredParameters.addAll(_generateMethodParameters())
      ..body = Code(_generateMethodBody());

    if (!_queryMethod.returnsStream || _queryMethod.returnsVoid) {
      builder..modifier = MethodModifier.async;
    }
    return builder.build();
  }

  List<Parameter> _generateMethodParameters() {
    return _queryMethod.parameters.map((parameter) {
      return Parameter((builder) => builder
        ..name = parameter.name
        ..type = refer(parameter.type.getDisplayString(
          withNullability: false,
        )));
    }).toList();
  }

  String _generateMethodBody() {
    final _methodBody = StringBuffer();

    final valueLists = _generateInClauseValueLists();
    if (valueLists.isNotEmpty) {
      _methodBody.write(valueLists.join(''));
    }

    final arguments = _generateArguments();
    if (_queryMethod.returnsVoid) {
      _methodBody.write(_generateNoReturnQuery(arguments));
      return _methodBody.toString();
    }

    final constructor = _queryMethod.queryable.constructor;
    final mapper = '(Map<String, dynamic> row) => $constructor';

    if (_queryMethod.returnsStream) {
      _methodBody.write(_generateStreamQuery(arguments, mapper));
    } else {
      _methodBody.write(_generateQuery(arguments, mapper));
    }

    return _methodBody.toString();
  }

  @nonNull
  List<String> _generateInClauseValueLists() {
    return _queryMethod.parameters
        .where((parameter) => parameter.type.isDartCoreList)
        .mapIndexed((index, parameter) {
      // TODO #403 what about type converters that map between e.g. string and list?
      final flattenedParameterType = parameter.type.flatten();
      String value;
      if (flattenedParameterType.isDefaultSqlType) {
        value = '\$value';
      } else {
        final typeConverter =
            _queryMethod.typeConverters.getClosest(flattenedParameterType);
        value = '\${_${typeConverter.name.decapitalize()}.encode(value)}';
      }
      return '''final valueList$index = ${parameter.displayName}.map((value) => "'$value'").join(', ');''';
    }).toList();
  }

  @nonNull
  List<String> _generateParameters() {
    return _queryMethod.parameters
        .where((parameter) => !parameter.type.isDartCoreList)
        .map((parameter) {
      if (parameter.type.isDefaultSqlType) {
        if (parameter.type.isDartCoreBool) {
          return '${parameter.displayName} == null ? null : (${parameter.displayName} ? 1 : 0)';
        } else {
          return parameter.displayName;
        }
      } else {
        final typeConverter =
            _queryMethod.typeConverters.getClosest(parameter.type);
        return '_${typeConverter.name.decapitalize()}.encode(${parameter.displayName})';
      }
    }).toList();
  }

  @nullable
  String _generateArguments() {
    final parameters = _generateParameters();
    return parameters.isNotEmpty ? '<dynamic>[${parameters.join(', ')}]' : null;
  }

  @nonNull
  String _generateNoReturnQuery(@nullable final String arguments) {
    final parameters = StringBuffer()..write("'${_queryMethod.query}'");
    if (arguments != null) parameters.write(', arguments: $arguments');
    if (_queryMethod.isRaw) parameters.write(', isRaw: true');
    return 'await _queryAdapter.queryNoReturn($parameters);';
  }

  @nonNull
  String _generateQuery(
    @nullable final String arguments,
    @nonNull final String mapper,
  ) {
    final parameters = StringBuffer()..write("'${_queryMethod.query}', ");
    if (arguments != null) parameters.write('arguments: $arguments, ');
    if (_queryMethod.isRaw) parameters.write('isRaw: true, ');
    parameters.write('mapper: $mapper');

    if (_queryMethod.returnsList) {
      return 'return _queryAdapter.queryList($parameters);';
    } else {
      return 'return _queryAdapter.query($parameters);';
    }
  }

  @nonNull
  String _generateStreamQuery(
    @nullable final String arguments,
    @nonNull final String mapper,
  ) {
    final queryableName = _queryMethod.queryable.name;
    final isView = _queryMethod.queryable is View;
    final parameters = StringBuffer()..write("'${_queryMethod.query}', ");
    if (arguments != null) parameters.write('arguments: $arguments, ');
    parameters
      ..write("queryableName: '$queryableName', ")
      ..write('isView: $isView, ')
      ..write('mapper: $mapper');

    if (_queryMethod.returnsList) {
      return 'return _queryAdapter.queryListStream($parameters);';
    } else {
      return 'return _queryAdapter.queryStream($parameters);';
    }
  }
}
