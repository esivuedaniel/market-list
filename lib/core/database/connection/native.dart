import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor connectDatabase({String name = 'market_list'}) {
  return driftDatabase(name: name);
}
