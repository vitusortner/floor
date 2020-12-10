/// Marks a method as a query method.
class Query {
  /// The SQLite query.
  final String value;

  final bool isRaw;

  /// Marks a method as a query method.
  const Query(this.value, {this.isRaw});
}
