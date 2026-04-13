import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class EscalationDialog extends StatefulWidget {
  final String title;
  final String description;
  final void Function(String? comment) onConfirm;

  const EscalationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirm,
  });

  @override
  State<EscalationDialog> createState() => _EscalationDialogState();
}

class _EscalationDialogState extends State<EscalationDialog> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.north_east, color: Colors.deepOrange, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 16))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: const TextStyle(fontSize: 13, color: FimmsColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a comment (optional)',
              hintStyle: TextStyle(fontSize: 13),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            final comment = _commentController.text.trim();
            widget.onConfirm(comment.isEmpty ? null : comment);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
