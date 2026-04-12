import 'package:flutter/material.dart';

import '../../../models/inspection.dart';

class ReinspectDialog extends StatefulWidget {
  final Inspection inspection;
  const ReinspectDialog({super.key, required this.inspection});

  @override
  State<ReinspectDialog> createState() => _ReinspectDialogState();
}

class _ReinspectDialogState extends State<ReinspectDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Order Re-inspection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inspection ${widget.inspection.id} — '
            'Score: ${widget.inspection.totalScore.round()}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for re-inspection',
              border: OutlineInputBorder(),
              hintText: 'Enter reason...',
            ),
            maxLines: 3,
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Re-inspection ordered (demo mode)')),
            );
          },
          child: const Text('Order Re-inspection'),
        ),
      ],
    );
  }
}
