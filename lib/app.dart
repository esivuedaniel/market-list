import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/di/injection.dart';
import 'package:market_list/core/router/app_router.dart';
import 'package:market_list/core/theme/app_theme.dart';
import 'package:market_list/core/widgets/error_view.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/core/widgets/loading_view.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';
import 'package:market_list/features/settings/presentation/widgets/onboarding_sheet.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class MarketListApp extends StatelessWidget {
  const MarketListApp({
    super.key,
    this.settingsCubit,
  });

  final SettingsCubit? settingsCubit;

  @override
  Widget build(BuildContext context) {
    final cubit = settingsCubit ?? getIt<SettingsCubit>();
    return BlocProvider<SettingsCubit>.value(
      value: cubit,
      child: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) => curr.firstListId != null,
        listener: (context, state) {
          if (state.firstListId != null) {
            appNavigatorKey.currentState?.pushNamed(
              AppRouter.listDetail,
              arguments: ListDetailArgs(listId: state.firstListId!),
            );
            context.read<SettingsCubit>().firstListHandled();
          }
        },
        builder: (context, state) {
          return MaterialApp(
            title: 'Market List',
            navigatorKey: appNavigatorKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _toThemeMode(state.settings?.themeMode),
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: _HomeGate(state: state),
          );
        },
      ),
    );
  }

  static ThemeMode _toThemeMode(AppThemeMode? mode) {
    return switch (mode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

class _HomeGate extends StatelessWidget {
  const _HomeGate({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      SettingsStatus.loading => const Scaffold(
          body: LoadingView(),
        ),
      SettingsStatus.failure => Scaffold(
          body: ErrorView(
            message: state.message ?? FailureMessages.databaseCannotOpen,
            onRetry: () {
              context.read<SettingsCubit>().start();
            },
          ),
        ),
      SettingsStatus.needsOnboarding => const Scaffold(
          body: Center(
            child: OnboardingSheet(),
          ),
        ),
      SettingsStatus.loaded => Builder(
          builder: (ctx) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRouter.lists),
            );
            if (route is MaterialPageRoute) {
              return route.builder(ctx);
            }
            return const SizedBox.shrink();
          },
        ),
    };
  }
}
