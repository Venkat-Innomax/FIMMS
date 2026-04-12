import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../shared_widgets/grade_chip.dart';

class AlertsPanel extends StatelessWidget {
  final List<Facility> facilities;
  final Map<String, Inspection> latestByFacility;

  const AlertsPanel({
    super.key,
    required this.facilities,
    required this.latestByFacility,
  });

  @override
  Widget build(BuildContext context) {
    // Facilities with critical/poor grade or urgent flag
    final alerts = <_AlertEntry>[];
    for (final f in facilities) {
      final insp = latestByFacility[f.id];
      if (insp == null) continue;
      if (insp.grade == Grade.critical ||
          insp.grade == Grade.poor ||
          insp.urgentFlag) {
        alerts.add(_AlertEntry(facility: f, inspection: insp));
      }
    }

    alerts.sort((a, b) {
      final gradeOrder = {
        Grade.critical: 0,
        Grade.poor: 1,
        Grade.average: 2,
        Grade.good: 3,
        Grade.excellent: 4,
      };
      return (gradeOrder[a.inspection.grade] ?? 9)
          .compareTo(gradeOrder[b.inspection.grade] ?? 9);
    });

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      decoration: BoxDecoration(
        color: FimmsColors.danger.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FimmsColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.warning_amber,
                    size: 18, color: FimmsColors.danger),
                const SizedBox(width: 6),
                const Text('Critical Alerts',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: FimmsColors.danger)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: FimmsColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${alerts.length}',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: FimmsColors.danger)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: alerts.length > 3 ? 180 : null,
            child: ListView.builder(
              shrinkWrap: alerts.length <= 3,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final a = alerts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(a.facility.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    subtitle: Text(
                      '${a.facility.mandalId} · ${DateFormat('dd MMM').format(a.inspection.datetime)}',
                      style: const TextStyle(fontSize: 10.5),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.inspection.urgentFlag) ...[
                          const UrgentBadge(),
                          const SizedBox(width: 6),
                        ],
                        GradeChip(grade: a.inspection.grade, compact: true),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertEntry {
  final Facility facility;
  final Inspection inspection;
  const _AlertEntry({required this.facility, required this.inspection});
}
