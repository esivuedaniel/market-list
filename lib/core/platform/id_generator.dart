import 'package:uuid/uuid.dart';

class IdGenerator {
  const IdGenerator([Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  String generate() => _uuid.v4();
}
