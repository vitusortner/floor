import 'package:code_builder/code_builder.dart';
import 'package:floor_generator/misc/annotation_expression.dart';
import 'package:floor_generator/misc/type_utils.dart';
import 'package:floor_generator/value_object/transaction_method.dart';
import 'package:floor_generator/writer/writer.dart';

class TransactionMethodWriter implements Writer {
  final TransactionMethod method;

  TransactionMethodWriter(final this.method);

  @override
  Method write() {
    return Method((builder) => builder
      ..annotations.add(overrideAnnotationExpression)
      ..returns = refer(method.returnType.getDisplayString(
        withNullability: true,
      ))
      ..name = method.name
      ..requiredParameters.addAll(_generateParameters())
      ..modifier = MethodModifier.async
      ..body = Code(_generateMethodBody()));
  }

  String _generateMethodBody() {
    final parameters =
        method.parameterElements.map((parameter) => parameter.name).join(', ');
    final methodCall = '${method.name}($parameters)';
    final innerType = method.returnType.flatten();
    final innerTypeName = innerType.getDisplayString(withNullability: false);
    final finalExpression = innerType.isVoid ? 'await' : 'return';

    return '''
    if (database is sqflite.Transaction) {
      $finalExpression super.$methodCall;
    } else {
      $finalExpression (database as sqflite.Database).transaction<$innerTypeName>((transaction) async {
        final innerListener = StreamController<Set<String>>.broadcast();
        final collector = innerListener.stream.fold<Set<String>>({}, (previous, element) => previous.union(element));
        
        final transactionDatabase = _\$${method.databaseName}(innerListener)..database = transaction;
        ${innerType.isVoid ? '' : 'final result ='} await transactionDatabase.${method.daoFieldName}.$methodCall;
        
        await innerListener.close();
        changeListener.add(await collector);
        ${innerType.isVoid ? '' : 'return result;'}
      });
    }
    ''';
  }

  List<Parameter> _generateParameters() {
    return method.parameterElements.map((parameter) {
      return Parameter((builder) => builder
        ..name = parameter.name
        ..type = refer(parameter.type.getDisplayString(
          withNullability: true,
        )));
    }).toList();
  }
}
