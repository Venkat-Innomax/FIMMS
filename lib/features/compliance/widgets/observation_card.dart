import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/compliance_item.dart';
import 'rectification_upload.dart';

class ObservationCard extends StatefulWidget {
  final ComplianceItem item;
  const ObservationCard({super.key, required this.item});

  @override
  State<ObservationCard> createState() => _ObservationCardState();
}

class _ObservationCardState extends State<ObservationCard> {
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusColor = switch (item.status) {
      ComplianceStatus.pending => FimmsColors.gradeAverage,
      ComplianceStatus.submitted => Colors.blue,
      ComplianceStatus.accepted => FimmsColors.success,
      ComplianceStatus.rejected => FimmsColors.danger,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: FimmsColors.outline),
      ),
      child: ExpansionTile(
        leading: Icon(
          item.status == ComplianceStatus.pending
              ? Icons.warning_amber
              : item.status == ComplianceStatus.accepted
                  ? Icons.check_circle
                  : Icons.pending,
          color: statusColor,
          size: 22,
        ),
        title: Text(
          item.observation,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              'Section: ${item.sectionId} · ${DateFormat('dd MMM').format(item.createdAt)}',
              style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status.label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor),
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Observation',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: FimmsColors.textMuted)),
                const SizedBox(height: 4),
                Text(item.observation, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),

                if (item.status == ComplianceStatus.pending) ...[
                  TextField(
                    controller: _responseController,
                    decoration: const InputDecoration(
                      labelText: 'Your response',
                      hintText: 'Describe the corrective action taken...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  const RectificationUpload(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Response submitted (demo mode)')),
                        );
                      },
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Submit Response'),
                    ),
                  ),
                ],

                if (item.facilityResponse != null) ...[
                  const Text('Facility Response',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: FimmsColors.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FimmsColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.facilityResponse!,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  if (item.evidencePaths.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${item.evidencePaths.length} evidence file(s) uploaded',
                      style: const TextStyle(
                          fontSize: 12, color: FimmsColors.textMuted),
                    ),
                  ],
                  if (item.respondedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Responded: ${DateFormat('dd MMM yyyy, HH:mm').format(item.respondedAt!)}',
                      style: const TextStyle(
                          fontSize: 11, color: FimmsColors.textMuted),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
