import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/complaint.dart';

class ComplaintTimeline extends StatelessWidget {
  final List<StatusChange> timeline;
  const ComplaintTimeline({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const Text('No timeline entries',
          style: TextStyle(color: FimmsColors.textMuted, fontSize: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < timeline.length; i++) ...[
          _TimelineNode(
            entry: timeline[i],
            isFirst: i == 0,
            isLast: i == timeline.length - 1,
          ),
        ],
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final StatusChange entry;
  final bool isFirst;
  final bool isLast;

  const _TimelineNode({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  Color get _dotColor => switch (entry.status) {
        ComplaintStatus.submitted => Colors.blue,
        ComplaintStatus.underReview => Colors.amber.shade700,
        ComplaintStatus.assigned => Colors.orange,
        ComplaintStatus.inProgress => Colors.purple,
        ComplaintStatus.escalatedToMandal => Colors.deepOrange,
        ComplaintStatus.escalatedToDistrict => Colors.red.shade700,
        ComplaintStatus.inspectionRequested => Colors.teal,
        ComplaintStatus.inspectionAssigned => FimmsColors.primary,
        ComplaintStatus.resolved => FimmsColors.success,
        ComplaintStatus.closed => Colors.grey,
        ComplaintStatus.draft => Colors.grey.shade400,
      };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 8, color: FimmsColors.outline),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _dotColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 2, color: FimmsColors.outline),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _dotColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.status.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _dotColor),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(entry.datetime),
                        style: const TextStyle(
                            fontSize: 10, color: FimmsColors.textMuted),
                      ),
                    ],
                  ),
                  if (entry.comment != null) ...[
                    const SizedBox(height: 4),
                    Text(entry.comment!,
                        style: const TextStyle(fontSize: 12)),
                  ],
                  const SizedBox(height: 2),
                  Text('by: ${entry.changedBy}',
                      style: const TextStyle(
                          fontSize: 10, color: FimmsColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
