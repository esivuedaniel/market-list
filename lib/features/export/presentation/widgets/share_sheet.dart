import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/di/injection.dart';
import 'package:market_list/features/export/presentation/cubit/share_cubit.dart';
import 'package:market_list/features/export/presentation/cubit/share_state.dart';

class ShareBottomSheet extends StatelessWidget {
  const ShareBottomSheet({
    super.key,
    required this.listId,
  });

  final String listId;

  static Future<void> show(BuildContext context, String listId) {
    final shareCubit = getIt<ShareCubit>();
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) => BlocProvider.value(
        value: shareCubit,
        child: ShareBottomSheet(listId: listId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShareCubit, ShareState>(
      listenWhen: (previous, current) =>
          current.status == ShareStatus.done || current.message != null,
      listener: (context, state) {
        if (state.message != null) {
          final messenger = ScaffoldMessenger.of(context);
          final msg = state.message!;
          context.read<ShareCubit>().messageHandled();
          Navigator.of(context).pop();
          messenger.showSnackBar(SnackBar(content: Text(msg)));
        } else if (state.status == ShareStatus.done) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isWorking = state.status == ShareStatus.working;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share list',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Share as PDF'),
                  trailing: isWorking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  enabled: !isWorking,
                  onTap: () => context.read<ShareCubit>().sharePdf(listId),
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: const Text('Share as text'),
                  enabled: !isWorking,
                  onTap: () => context.read<ShareCubit>().shareText(listId),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
