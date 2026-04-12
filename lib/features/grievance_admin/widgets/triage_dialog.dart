import 'package:flutter/material.dart';

import '../../../models/complaint.dart';

class TriageDialog extends StatefulWidget {
  final Complaint complaint;
  const TriageDialog({super.key, required this.complaint});

  @override
  State<TriageDialog> createState() => _TriageDialogState();
}

class _TriageDialogState extends State<TriageDialog> {
  late ComplaintPriority _priority;
  late ComplaintCategory _category;
  final _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _priority = widget.complaint.priority;
    _category = widget.complaint.category;
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Triage Complaint'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.complaint.description,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text('Priority',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final p in ComplaintPriority.values)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Category',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButton<ComplaintCategory>(
              value: _category,
              isExpanded: true,
              items: ComplaintCategory.values
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(),
                hintText: 'Triage notes...',
              ),
              maxLines: 2,
            ),
          ],
        ),
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
              const SnackBar(content: Text('Assigned (demo mode)')),
            );
          },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
