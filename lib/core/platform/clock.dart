class Clock {
  const Clock();

  DateTime now() => DateTime.now().toUtc();

  int nowEpochMs() => DateTime.now().toUtc().millisecondsSinceEpoch;
}
