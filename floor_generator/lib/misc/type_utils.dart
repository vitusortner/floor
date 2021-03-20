import 'dart:typed_data';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

extension SupportedTypeChecker on DartType {
  /// Whether this [DartType] is either
  /// - String
  /// - bool
  /// - int
  /// - double
  /// - Uint8List
  bool get isDefaultSqlType {
    return TypeChecker.any([
      _stringTypeChecker,
      _boolTypeChecker,
      _intTypeChecker,
      _doubleTypeChecker,
      _uint8ListTypeChecker,
    ]).isExactlyType(this);
  }
}

extension Uint8ListTypeChecker on DartType {
  bool get isUint8List =>
      getDisplayString(withNullability: false) == 'Uint8List';
}

extension StreamTypeChecker on DartType {
  bool get isStream => _streamTypeChecker.isExactlyType(this);
}

extension FlattenUtil on DartType {
  DartType flatten() {
    return (this as ParameterizedType).typeArguments.first;
  }
}

extension AnnotationChecker on Element {
  bool hasAnnotation(final Type type) {
    return _typeChecker(type).hasAnnotationOfExact(this);
  }

  /// Returns the first annotation object found on [type]
  DartObject getAnnotation(final Type type) {
    return _typeChecker(type)
        .firstAnnotationOfExact(this)!; // TODO return nullable?
  }
}

TypeChecker _typeChecker(final Type type) => TypeChecker.fromRuntime(type);

final _stringTypeChecker = _typeChecker(String);

final _boolTypeChecker = _typeChecker(bool);

final _intTypeChecker = _typeChecker(int);

final _doubleTypeChecker = _typeChecker(double);

final _uint8ListTypeChecker = _typeChecker(Uint8List);

final _streamTypeChecker = _typeChecker(Stream);
