import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class QueryMethodProcessorError {
  final MethodElement _methodElement;

  QueryMethodProcessorError(final MethodElement methodElement)
      : assert(methodElement != null),
        _methodElement = methodElement;

  InvalidGenerationSourceError get noQueryDefined {
    return InvalidGenerationSourceError(
      "You didn't define a query or the query was not a string literal.",
      todo: 'Define a query by adding SQL to the @Query() annotation.',
      element: _methodElement,
    );
  }

  InvalidGenerationSourceError get doesNotReturnFutureNorStream {
    return InvalidGenerationSourceError(
      'All query methods have to return a Future or Stream.',
      todo: 'Define the return type as Future or Stream.',
      element: _methodElement,
    );
  }

  InvalidGenerationSourceError get doesNotReturnQueryableOrPrimitive {
    //TODO Typeconverters
    return InvalidGenerationSourceError(
      'The inner return type of a query method can only return a type which '
      'was defined as a @DatabaseView or an @Entity or a primitive type '
      '(void, int, double, String or Uint8List)',
      todo: 'Define the return type in a way that contains no types other than '
          'primitive types and Entities/DatabaseViews.',
      element: _methodElement,
    );
  }

  InvalidGenerationSourceError get voidReturnCannotBeList {
    return InvalidGenerationSourceError(
      'The given query cannot return a List<void>.',
      todo:
          "Set the return type to Future<void> or don't use void for the return type.",
      element: _methodElement,
    );
  }

  InvalidGenerationSourceError get voidReturnCannotBeStream {
    return InvalidGenerationSourceError(
      'The given query cannot return a Stream<void>.',
      todo:
          "Set the return type to Future<void> or don't use void for the return type.",
      element: _methodElement,
    );
  }
}
