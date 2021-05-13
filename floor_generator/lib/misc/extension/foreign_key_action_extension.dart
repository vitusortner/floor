import 'package:floor_annotation/floor_annotation.dart';

extension ForeignKeyActionExtension on ForeignKeyAction {
  String toSql() {
    switch (this) {
      case ForeignKeyAction.noAction:
        return 'NO ACTION';
      case ForeignKeyAction.restrict:
        return 'RESTRICT';
      case ForeignKeyAction.setNull:
        return 'SET NULL';
      case ForeignKeyAction.setDefault:
        return 'SET DEFAULT';
      case ForeignKeyAction.cascade:
        return 'CASCADE';
    }
  }

  bool changesChildren() {
    switch (this) {
      case ForeignKeyAction.noAction:
      case ForeignKeyAction.restrict:
        return false;
      case ForeignKeyAction.setNull:
      case ForeignKeyAction.setDefault:
      case ForeignKeyAction.cascade:
        return true;
    }
  }
}
