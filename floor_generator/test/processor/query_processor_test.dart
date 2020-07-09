import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:floor_generator/processor/query_analyzer/engine.dart';
import 'package:floor_generator/processor/query_processor.dart';
import 'package:floor_generator/value_object/entity.dart';
import 'package:floor_generator/value_object/query.dart';
//import 'package:floor_generator/value_object/view.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqlparser/sqlparser.dart' hide View;
import 'package:test/test.dart';

import '../test_utils.dart';

//TODO new tests:
// Errors:
// - parsing error
// - analyzer error (e.g. "IN (5,'3')" )
// - numbered variables in query
// - sql/method parameter mismatch 1 (mayb copied from qm-processor-test)
// - sql/method parameter mismatch 2 (mayb copied from qm-processor-test)
// Normal behaviour:
// - complex variable scenario (multiple lists, used many times with normal vars in between)
// - no-dependencies scenario in select
// - proper outputs (dependencies, affected, output) for update
// - proper outputs (dependencies, affected, output) for delete
// - proper outputs (dependencies, affected, output) for insert
//

void main() {
  List<Entity> entities;
  //List<View> views;
  AnalyzerEngine engine;

  setUpAll(() async {
    engine = AnalyzerEngine();

    entities = await getEntities(engine);

    /*views =*/ await getViews(engine);
  });

  test('create simple query object', () async {
    final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person')
      Future<List<Person>> findAllPersons();      
    ''');

    final actual =
        QueryProcessor(methodElement, 'SELECT * FROM Person', engine).process();

    expect(
      actual,
      equals(Query(
        'SELECT * FROM Person',
        [],
        [
          SqlResultColumn(
              'id',
              const ResolveResult(
                  ResolvedType(type: BasicType.int, nullable: true))),
          SqlResultColumn(
              'name',
              const ResolveResult(
                  ResolvedType(type: BasicType.text, nullable: true))),
        ],
        {entities.firstWhere((e) => e.name == 'Person')},
        {},
      )),
    );
  });

  test('create complex query object', () async {
    final methodElement = await _createQueryMethodElement('''
      @Query("SELECT *, name='Jules', length(name), :arg1 as X FROM Name WHERE length(name) in (:lengths)")
      Future<void> findAllPersons(List<int> lengths, Uint8List arg1);      
    ''');

    final actual = QueryProcessor(
            methodElement,
            'SELECT *, name=\'Jules\', length(name), :arg1 as X FROM Name WHERE length(name) in (:lengths)',
            engine)
        .process();

    expect(
      actual,
      equals(Query(
        'SELECT *, name=\'Jules\', length(name), ?1 as X FROM Name WHERE length(name) in (:varlist)',
        [ListParameter(79, 'lengths')],
        [
          SqlResultColumn(
              'name',
              const ResolveResult(
                  ResolvedType(type: BasicType.text, nullable: true))),
          SqlResultColumn(
              'name=\'Jules\'',
              const ResolveResult(ResolvedType(
                  type: BasicType.int, nullable: false, hint: IsBoolean()))),
          SqlResultColumn(
              'length(name)',
              const ResolveResult(
                  ResolvedType(type: BasicType.int, nullable: false))),
          SqlResultColumn(
              'X',
              const ResolveResult(
                  ResolvedType(type: BasicType.blob, nullable: true))),
        ],
        {entities.firstWhere((e) => e.name == 'Person')},
        {},
      )),
    );
  });
  group('query parsing', () {
/*
    test('parse query', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id')
      Future<Person> findPerson(int id);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process()
              .query
              .sql;

      expect(actual, equals('SELECT * FROM Person WHERE id = ?1'));
    });

    test('parse multiline query', () async {
      final methodElement = await _createQueryMethodElement("""
        @Query('''
          SELECT * FROM person
          WHERE id = :id AND name = :name
        ''')
        Future<Person> findPersonByIdAndName(int id, String name);
      """);

      final actual =
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process()
              .query
              .sql;

      expect(
        actual,
        equals(
            '          SELECT * FROM person\n          WHERE id = ?1 AND name = ?2\n        '),
      );
    });

    test('parse concatenated string query', () async {
      final methodElement = await _createQueryMethodElement('''
        @Query('SELECT * FROM person '
            'WHERE id = :id AND name = :name')
        Future<Person> findPersonByIdAndName(int id, String name);    
      ''');

      final actual =
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process()
              .query
              .sql;

      expect(
        actual,
        equals('SELECT * FROM person WHERE id = ?1 AND name = ?2'),
      );
    });

    test('Parse IN clause', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query("update Person set name = '1' where id in (:ids)")
      Future<void> setRated(List<int> ids);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], engine).process().query.sql;

      expect(
        actual,
        equals(r'''update Person set name = '1' where id in (:varlist)'''),
      );
    });

    test('Parse query with multiple IN clauses', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query("update Person set name = '1' where id in (:ids) and name in (:bar)")
      Future<void> setRated(List<int> ids, List<String> bar);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], engine).process().query.sql;

      expect(
        actual,
        equals(
          r'''update Person set name = '1' where id in (:varlist) '''
          r'and name in (:varlist)',
        ),
      );
    });

    test('Parse query with IN clause and other parameter', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query("update Person set name = '1' where id in (:ids) AND name = :bar")
      Future<void> setRated(List<int> ids, int bar);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [], engine).process().query.sql;

      expect(
        actual,
        equals(
          "update Person set name = '1' where id in (:varlist) "
          'AND name = ?1',
        ),
      );
    });

    test('Parse query with LIKE operator', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE name LIKE :name')
      Future<List<Person>> findPersonsWithNamesLike(String name);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process()
              .query
              .sql;

      expect(actual, equals('SELECT * FROM Person WHERE name LIKE ?1'));
    });

    test('Parse query with commas', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT :table, :otherTable')
      Future<void> findPersonsWithNamesLike(String table, String otherTable);
    ''');

      final actual =
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process()
              .query
              .sql;

      expect(actual, equals('SELECT ?1, ?2'));
    });*/
  });

  group('errors', () {
    test('parser exception when query string has more than one query',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT 1;SELECT 2')
      Future<List<Person>> findAllPersons();
    ''');

      final actual = () =>
          QueryProcessor(methodElement, 'SELECT 1;SELECT 2', engine).process();
      expect(
          actual,
          throwsInvalidGenerationSourceErrorWithMessagePrefix(
              InvalidGenerationSourceError('The query contained parser errors:',
                  element: methodElement)));
    });
    /*test('exception when method does not return future', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person')
      List<Person> findAllPersons();
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process();

      final error =
          QueryMethodProcessorError(methodElement).doesNotReturnFutureNorStream;
      expect(actual, throwsInvalidGenerationSourceError(error));
    });

    test('exception when query is empty string', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('')
      Future<List<Person>> findAllPersons();
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process();

      final error = QueryMethodProcessorError(methodElement).noQueryDefined;
      expect(actual, throwsInvalidGenerationSourceError(error));
    });

    test('exception when query is null', () async {
      final methodElement = await _createQueryMethodElement('''
      @Query()
      Future<List<Person>> findAllPersons();
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process();

      final error = QueryMethodProcessorError(methodElement).noQueryDefined;
      expect(actual, throwsInvalidGenerationSourceError(error));
    });

    test('exception when query arguments do not match method parameters',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id AND name = :name')
      Future<Person> findPersonByIdAndName(int id);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process();

      //maybe mock ColonNamedVariable, or else the following line will not match.
      // final error = QueryAnalyzerError(methodElement).queryParameterMissingInMethod(ColonNamedVariable(ColonVariableToken(null,':name')));
      expect(
          actual, throwsA(const TypeMatcher<InvalidGenerationSourceError>()));
    });

    test('exception when query arguments do not match method parameters',
        () async {
      final methodElement = await _createQueryMethodElement('''
      @Query('SELECT * FROM Person WHERE id = :id')
      Future<Person> findPersonByIdAndName(int id, String name);
    ''');

      final actual = () =>
          QueryMethodProcessor(methodElement, [...entities, ...views], engine)
              .process();
      expect(
          actual, throwsA(const TypeMatcher<InvalidGenerationSourceError>()));
    });*/
  });
}

Future<MethodElement> _createQueryMethodElement(
  final String method,
) async {
  final library = await resolveSource('''
      library test;
      
      import 'dart:typed_data';
      import 'package:floor_annotation/floor_annotation.dart';

      @dao
      abstract class PersonDao {
        $method
      }
      
      @entity
      class Person {
        @primaryKey
        final int id;
      
        final String name;
      
        Person(this.id, this.name);
      }
      
      @DatabaseView("SELECT DISTINCT(name) AS name from person")
      class Name {
        final String name;
      
        Name(this.name);
      }
    ''', (resolver) async {
    return LibraryReader(await resolver.findLibraryByName('test'));
  });

  return library.classes.first.methods.first;
}