import 'package:floor/floor.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'database.g.dart';

@Database()
abstract class TestDatabase extends FloorDatabase {
  static Future<TestDatabase> openDatabase() async => _$open();

  @Query('SELECT * FROM Person')
  Future<List<Person>> findAllPersons();

  @Query('SELECT * FROM Person WHERE id = :id')
  Future<Person> findPersonById(int id);

  @insert
  Future<void> insertPerson(Person person);

  @update
  Future<void> updatePerson(Person person);

  @delete
  Future<void> deletePerson(Person person);
}

@entity
class Person {
  @PrimaryKey()
  final int id;
  final String name;

  Person(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Person{id: $id, name: $name}';
  }
}
