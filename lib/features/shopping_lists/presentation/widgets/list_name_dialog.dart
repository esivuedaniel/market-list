import 'package:flutter/material.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/text_normalizer.dart';
import 'package:market_list/core/widgets/failure_messages.dart';

class ListNameDialog extends StatefulWidget {
  const ListNameDialog({
    super.key,
    required this.title,
    this.initialName = '',
    this.confirmText = 'Save',
  });

  final String title;
  final String initialName;
  final String confirmText;

  @override
  State<ListNameDialog> createState() => _ListNameDialogState();
}

class _ListNameDialogState extends State<ListNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final normalized = TextNormalizer.normalize(_controller.text);
    if (normalized.isEmpty) {
      setState(() => _error = FailureMessages.enterListName);
      return;
    }
    if (TextNormalizer.codePointLength(normalized) >
        AppLimits.maxListNameLength) {
      setState(() => _error = FailureMessages.listNameTooLong);
      return;
    }
    Navigator.of(context).pop(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'List name',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
