import 'package:floor_generator/misc/extension/iterable_extension.dart';
import 'package:test/test.dart';

void main() {
  group('sortedByDescending', () {
    test('sorts iterable descending by selector', () {
      final actual = [_Box(4), _Box(0), _Box(2), _Box(1), _Box(3)]
          .sortedByDescending((box) => box.number);

      expect(actual, equals([_Box(4), _Box(3), _Box(2), _Box(1), _Box(0)]));
    });
  });

  group('mapNotNull', () {
    test('applies transformation yielding only non-null values', () {
      final actual = [_NullableBox(0), _NullableBox(null), _NullableBox(1)]
          .mapNotNull((box) => box.number);

      expect(actual, equals([0, 1]));
    });
  });

  group('distinctBy', () {
    test('distincts values by selector', () {
      final actual = [_Box(1), _Box(1), _Box(0), _Box(2), _Box(2)]
          .distinctBy((box) => box.number);

      expect(actual, equals([_Box(1), _Box(0), _Box(2)]));
    });
  });

  group('toSetLiteral', () {
    test('empty Set from empty set', () {
      expect(<String>{}.toSetLiteral(), equals('const {}'));
    });

    test('empty Set from empty list', () {
      expect(<String>[].toSetLiteral(), equals('const {}'));
    });

    test('empty Set from empty set without const', () {
      expect(<String>{}.toSetLiteral(withConst: false), equals('{}'));
    });

    test('set with elements', () {
      expect(<String>{'that', 'escaped \'String\''}.toSetLiteral(),
          equals("const {'that', 'escaped \\\'String\\\''}"));
    });

    test('list with duplicate elements only shows distinct elements', () {
      expect(
          <String>['that', 'escaped \'String\'', 'that', 'that'].toSetLiteral(),
          equals("const {'that', 'escaped \\\'String\\\''}"));
    });
  });
}

class _Box {
  final int number;

  _Box(this.number);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Box &&
          runtimeType == other.runtimeType &&
          number == other.number;

  @override
  int get hashCode => number.hashCode;
}

class _NullableBox {
  final int? number;

  _NullableBox(this.number);
}
