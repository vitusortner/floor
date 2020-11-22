/// Allows customization of the column associated with this field.
class ColumnInfo {
  /// The custom name of the column.
  final String? name;

  // TODO #375 if nullable, we need a default value
  /// Defines if the associated column is allowed to contain 'null'.
  final bool nullable;

  // TODO #375 change nullable to false as default
  const ColumnInfo({this.name, this.nullable = true});
}
