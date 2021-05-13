import 'dart:collection';
import 'string_extension.dart';

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> sortedByDescending(Comparable Function(T element) selector) {
    return toList()..sort((b, a) => selector(a).compareTo(selector(b)));
  }

  Iterable<R> mapNotNull<R>(R? Function(T element) transform) sync* {
    for (final element in this) {
      final transformed = transform(element);
      if (transformed != null) yield transformed;
    }
  }

  /// Returns a new lazy [Iterable] containing only elements from the collection
  /// having distinct keys returned by the given [selector] function.
  ///
  /// The elements in the resulting list are in the same order as they were in
  /// the source collection.
  Iterable<T> distinctBy<R>(R Function(T element) selector) sync* {
    final existing = HashSet<R>();
    for (final current in this) {
      if (existing.add(selector(current))) yield current;
    }
  }
}

extension StringIterableExtension on Iterable<String> {
  String toSetLiteral({bool withConst = true}) {
    final content = distinctBy((element) => element)
        .map<String>((e) => e.toLiteral())
        .join(', ');
    final cnst = withConst ? 'const ' : '';
    return '$cnst{$content}';
  }
}
