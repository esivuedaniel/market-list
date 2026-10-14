import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:market_list/app.dart';
import 'package:market_list/core/di/injection.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        debugPrint(details.exceptionAsString());
      };

      await configureDependencies();

      final regionCode = PlatformDispatcher.instance.locale.countryCode;
      getIt<SettingsCubit>().start(regionCode);

      runApp(const MarketListApp());
    },
    (error, stack) {
      debugPrint('$error\n$stack');
    },
  );
}
