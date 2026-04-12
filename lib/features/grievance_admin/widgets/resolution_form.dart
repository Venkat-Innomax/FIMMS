import 'package:flutter/material.dart';

class ResolutionForm extends StatefulWidget {
  const ResolutionForm({super.key});

  @override
  State<ResolutionForm> createState() => _ResolutionFormState();
}

class _ResolutionFormState extends State<ResolutionForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mark as Resolved',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Resolution summary',
              hintText: 'Describe how the issue was resolved...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Complaint resolved (demo mode)')),
                );
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Resolve'),
            ),
          ),
        ],
      ),
    );
  }
}
