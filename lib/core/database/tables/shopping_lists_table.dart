import 'package:drift/drift.dart';

@DataClassName('ShoppingListRow')
class ShoppingListsTable extends Table {
  @override
  String get tableName => 'shopping_lists';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currencyCode => text().named('currency_code')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (length(name) >= 1 AND length(name) <= 60)',
        'CHECK (currency_code IN (\'NGN\', \'GHS\', \'KES\', \'ZAR\', \'USD\', \'GBP\', \'EUR\'))',
      ];
}
