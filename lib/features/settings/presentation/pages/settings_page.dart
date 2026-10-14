import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (prev, curr) => curr.message != null,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<SettingsCubit>().messageHandled();
        }
      },
      builder: (context, state) {
        final settings = state.settings;
        final currentCurrency = settings?.defaultCurrency ?? CurrencyCode.usd;
        final currentTheme = settings?.themeMode ?? AppThemeMode.system;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              ListTile(
                title: const Text('Default currency'),
                subtitle: const Text('Applies to new lists only.'),
                trailing: Text(
                  '${currentCurrency.symbol}  ${currentCurrency.code}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () => _showCurrencyDialog(context, currentCurrency),
              ),
              const Divider(),
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(_themeLabel(currentTheme)),
                onTap: () => _showThemeDialog(context, currentTheme),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your lists live on this phone. Phone backup may restore '
                      'them on a new phone. The app collects no data.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context, CurrencyCode current) {
    showDialog<CurrencyCode>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Default currency'),
          content: SingleChildScrollView(
            child: RadioGroup<CurrencyCode>(
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  Navigator.of(dialogContext).pop(val);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CurrencyCode.values.map((code) {
                  return RadioListTile<CurrencyCode>(
                    value: code,
                    title: Text('${code.symbol}  ${code.code}'),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    ).then((selected) {
      if (selected != null && context.mounted) {
        context.read<SettingsCubit>().setDefaultCurrency(selected);
      }
    });
  }

  void _showThemeDialog(BuildContext context, AppThemeMode current) {
    showDialog<AppThemeMode>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Theme'),
          content: RadioGroup<AppThemeMode>(
            groupValue: current,
            onChanged: (val) {
              if (val != null) {
                Navigator.of(dialogContext).pop(val);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppThemeMode.values.map((mode) {
                return RadioListTile<AppThemeMode>(
                  value: mode,
                  title: Text(_themeLabel(mode)),
                );
              }).toList(),
            ),
          ),
        );
      },
    ).then((selected) {
      if (selected != null && context.mounted) {
        context.read<SettingsCubit>().setThemeMode(selected);
      }
    });
  }

  String _themeLabel(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }
}
