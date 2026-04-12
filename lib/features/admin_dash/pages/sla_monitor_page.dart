import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../shared_widgets/grade_chip.dart';

class SlaMonitorPage extends ConsumerWidget {
  const SlaMonitorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return facilitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (facilities) {
        final inspections = inspectionsAsync.valueOrNull ?? <Inspection>[];
        final latestByFacility = <String, Inspection>{};
        for (final i in inspections) {
          final existing = latestByFacility[i.facilityId];
          if (existing == null || i.datetime.isAfter(existing.datetime)) {
            latestByFacility[i.facilityId] = i;
          }
        }

        final now = DateTime.now();
        final rows = facilities.map((f) {
          final latest = latestByFacility[f.id];
          final daysSince = latest != null
              ? now.difference(latest.datetime).inDays
              : 999;
          return _SlaRow(facility: f, latestInspection: latest, daysSince: daysSince);
        }).toList()
          ..sort((a, b) => b.daysSince.compareTo(a.daysSince));

        final overdueCount = rows.where((r) => r.daysSince > 30).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _StatCard(
                    label: 'Total Facilities',
                    value: '${facilities.length}',
                    color: FimmsColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Overdue (>30 days)',
                    value: '$overdueCount',
                    color: FimmsColors.danger,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Never Inspected',
                    value: '${rows.where((r) => r.latestInspection == null).length}',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(FimmsColors.surface),
                    columns: const [
                      DataColumn(label: Text('Facility')),
                      DataColumn(label: Text('Mandal')),
                      DataColumn(label: Text('Type')),
                      DataColumn(
                          label: Text('Days Since'), numeric: true),
                      DataColumn(label: Text('Last Inspection')),
                      DataColumn(label: Text('Grade')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: rows.map((r) {
                      final isOverdue = r.daysSince > 30;
                      final isWarning = r.daysSince > 14 && r.daysSince <= 30;
                      return DataRow(
                        color: isOverdue
                            ? WidgetStateProperty.all(
                                FimmsColors.danger.withValues(alpha: 0.05))
                            : null,
                        cells: [
                          DataCell(Text(r.facility.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(Text(r.facility.mandalId)),
                          DataCell(Text(r.facility.type == FacilityType.hostel
                              ? 'Hostel'
                              : 'Hospital')),
                          DataCell(Text(
                            r.latestInspection != null
                                ? '${r.daysSince}d'
                                : 'Never',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isOverdue
                                  ? FimmsColors.danger
                                  : isWarning
                                      ? FimmsColors.warning
                                      : FimmsColors.textMuted,
                            ),
                          )),
                          DataCell(Text(
                            r.latestInspection != null
                                ? DateFormat('dd MMM yyyy')
                                    .format(r.latestInspection!.datetime)
                                : '—',
                          )),
                          DataCell(r.latestInspection != null
                              ? GradeChip(
                                  grade: r.latestInspection!.grade,
                                  compact: true)
                              : const Text('—')),
                          DataCell(_SlaStatusBadge(
                            isOverdue: isOverdue,
                            isWarning: isWarning,
                            isNever: r.latestInspection == null,
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SlaRow {
  final Facility facility;
  final Inspection? latestInspection;
  final int daysSince;
  const _SlaRow({
    required this.facility,
    required this.latestInspection,
    required this.daysSince,
  });
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SlaStatusBadge extends StatelessWidget {
  final bool isOverdue;
  final bool isWarning;
  final bool isNever;
  const _SlaStatusBadge({
    required this.isOverdue,
    required this.isWarning,
    required this.isNever,
  });

  @override
  Widget build(BuildContext context) {
    final (String text, Color color) = isNever
        ? ('NEVER', Colors.grey)
        : isOverdue
            ? ('OVERDUE', FimmsColors.danger)
            : isWarning
                ? ('DUE SOON', FimmsColors.warning)
                : ('OK', FimmsColors.success);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
