import 'package:flutter_test/flutter_test.dart';

import '../test_util/extensions.dart';
import 'dao/person_dao.dart';
import 'database.dart';
import 'model/dog.dart';
import 'model/person.dart';

void main() {
  group('stream query tests', () {
    late TestDatabase database;
    late PersonDao personDao;

    setUp(() async {
      database = await $FloorTestDatabase.inMemoryDatabaseBuilder().build();
      personDao = database.personDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('initially emit persistent data', () async {
      final person = Person(1, 'Simon');
      await personDao.insertPerson(person);

      final actual = personDao.findAllPersonsAsStream();

      expect(actual, emits([person]));
    });

    group('insert change', () {
      test('find person by id as stream', () async {
        final person = Person(1, 'Simon');
        await personDao.insertPerson(person);

        final actual = personDao.findPersonByIdAsStream(person.id!);

        expect(actual, emits(person));
      });

      test('find all persons as stream', () async {
        final persons = [Person(1, 'Simon'), Person(2, 'Frank')];

        final actual = personDao.findAllPersonsAsStream();
        expect(actual, emits(<List<Person>>[]));

        await personDao.insertPersons(persons);
        expect(actual, emits(persons));
      });

      test('initially emits persistent data then new', () async {
        final persons = [Person(1, 'Simon'), Person(2, 'Frank')];
        final persons2 = [Person(3, 'Paul'), Person(4, 'George')];
        await personDao.insertPersons(persons);

        final actual = personDao.findAllPersonsAsStream();
        expect(actual, emits(persons));

        await personDao.insertPersons(persons2);
        expect(actual, emits(persons + persons2));
      });
    });

    group('update change', () {
      test('update item when querying single item', () async {
        final person = Person(1, 'Simon');
        final updatedPerson = Person(person.id, 'Frank');
        await personDao.insertPerson(person);

        final actual = personDao.findPersonByIdAsStream(person.id!);
        expect(actual, emits(person));
        await personDao.updatePerson(updatedPerson);

        expect(actual, emits(updatedPerson));
      });

      test('update item when querying list of items', () async {
        final person = Person(1, 'Simon');
        await personDao.insertPerson(person);

        final actual = personDao.findAllPersonsAsStream();
        expect(actual, emits([person]));

        final updatedPerson = Person(person.id, 'Frank');
        await personDao.updatePerson(updatedPerson);
        expect(actual, emits([updatedPerson]));
      });

      test('update items when querying list of items', () async {
        final persons = [Person(1, 'Simon'), Person(2, 'Frank')];
        final updatedPersons = persons
            .map((person) => Person(person.id, person.name.reversed()))
            .toList();
        await personDao.insertPersons(persons);

        final actual = personDao.findAllPersonsAsStream();
        expect(actual, emits(persons));

        await personDao.updatePersons(updatedPersons);
        expect(actual, emits(updatedPersons));
      });
    });

    group('deletion change', () {
      test('delete item', () async {
        final person = Person(1, 'Simon');
        await personDao.insertPerson(person);

        final actual = personDao.findAllPersonsAsStream();
        expect(actual, emits([person]));

        await personDao.deletePerson(person);
        expect(actual, emits(<Person>[]));
      });

      test('delete items', () async {
        final persons = [Person(1, 'Simon'), Person(2, 'Frank')];
        await personDao.insertPersons(persons);

        final actual = personDao.findAllPersonsAsStream();
        expect(actual, emits(persons));

        await personDao.deletePersons(persons);
        expect(actual, emits(<Person>[]));
      });
    });

    test('regression test streaming updates from other Dao', () async {
      final person1 = Person(1, 'Simon');
      final person2 = Person(2, 'Frank');
      final dog1 = Dog(1, 'Dog', 'Doggie', person1.id!);
      final dog2 = Dog(2, 'OtherDog', 'Doggo', person2.id!);

      final actual = personDao.findAllDogsOfPersonAsStream(person1.id!);
      expect(
          actual,
          emitsInOrder(<List<Dog>>[
            [], // initial state,
            [], // after inserting person1, [1]
            [], // after inserting person2, [1]
            [dog1], // after inserting dog1
            [dog1], // after inserting dog2
            [], // after removing person1, which triggers cascade remove
          ]));
      // [1] due to insert method having onConflict:replace, dog entries could be affected by this query, so a stream event is triggered.

      await personDao.insertPerson(person1);
      // avoid that delete happens before the re-execution of
      // the select query for the stream
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await personDao.insertPerson(person2);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await database.dogDao.insertDog(dog1);

      await database.dogDao.insertDog(dog2);

      // avoid that delete happens before the re-execution of
      // the select query for the stream
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await database.personDao.deletePerson(person1);
    });
    group('transaction triggers', () {
      test('transaction should only trigger once per completed transaction',
          () async {
        final actual = personDao.findAllPersonsAsStream();
        expect(
            actual,
            emitsInOrder(<dynamic>[
              <Person>[], // initial state,
              [
                Person(0, ' P0'),
                Person(1, ' P1'),
                Person(2, ' P2'),
                Person(3, ' P3'),
              ], // after first fill
              [
                Person(0, 'x P0'),
                Person(1, 'x P1'),
                Person(2, 'x P2'),
                Person(3, 'x P3'),
              ], // after second fill,
              emitsDone
            ]));

        await personDao.fillDatabase('');
        await personDao.fillDatabase('x');
        // avoid that closing happens before the re-execution of
        // the select query for the stream
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await database.close();
      });
      test('failing transaction should not trigger stream', () async {
        final actual = personDao.findAllPersonsAsStream();
        expect(
            actual,
            emitsInOrder(<dynamic>[
              <Person>[], // initial state,
              emitsDone // do no emit anything else, since statements within
              // transaction should not trigger new stream events
            ]));
        try {
          await personDao.failingTransaction();
        } catch (_) {}
        // close database to avoid deadlock (expect emitsDone waits for closing of Database
        // and database will be closed in tearDown after expect finishes
        await database.close();
      });
    });
  });
}
