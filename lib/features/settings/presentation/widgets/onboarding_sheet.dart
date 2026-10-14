import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';

class OnboardingSheet extends StatefulWidget {
  const OnboardingSheet({super.key});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  CurrencyCode? _selected;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SettingsCubit>();
    _selected = cubit.state.suggestedCurrency ??
        cubit.state.settings?.defaultCurrency ??
        CurrencyCode.usd;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (prev, curr) => curr.message != null,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<SettingsCubit>().messageHandled();
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose your currency',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: RadioGroup<CurrencyCode>(
                    groupValue: _selected,
                    onChanged: (val) {
                      if (val != null) setState(() => _selected = val);
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          context
                              .read<SettingsCubit>()
                              .completeOnboarding(_selected!);
                        },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
