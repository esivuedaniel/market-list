import 'package:flutter/material.dart';
import 'package:market_list/app.dart';
import 'package:market_list/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MarketListApp());
}
