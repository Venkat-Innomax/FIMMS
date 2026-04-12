import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/complaint_repository.dart';
import '../../../models/complaint.dart';

class MergeDialog extends ConsumerWidget {
  final String currentComplaintId;
  final String facilityId;

  const MergeDialog({
    super.key,
    required this.currentComplaintId,
    required this.facilityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Merge Complaints'),
      content: FutureBuilder<List<Complaint>>(
        future:
            ref.read(complaintRepositoryProvider).byFacility(facilityId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final others = snapshot.data!
              .where((c) => c.id != currentComplaintId)
              .toList();

          if (others.isEmpty) {
            return const Text(
                'No other complaints for this facility to merge with.');
          }

          return SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select complaints to merge:',
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                for (final c in others)
                  CheckboxListTile(
                    dense: true,
                    title: Text(c.description,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text('${c.id} · ${c.status.label}',
                        style: const TextStyle(fontSize: 10)),
                    value: false,
                    onChanged: (_) {},
                  ),
              ],
            ),
          );
        },
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
              const SnackBar(content: Text('Complaints merged (demo mode)')),
            );
          },
          child: const Text('Merge'),
        ),
      ],
    );
  }
}
