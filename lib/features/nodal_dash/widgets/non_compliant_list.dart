import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/inspection.dart';
import '../../shared_widgets/grade_chip.dart';

class NonCompliantList extends ConsumerStatefulWidget {
  const NonCompliantList({super.key});

  @override
  ConsumerState<NonCompliantList> createState() => _NonCompliantListState();
}

class _NonCompliantListState extends ConsumerState<NonCompliantList> {
  String? _mandalFilter;

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final mandalsAsync = ref.watch(mandalsProvider);

    return facilitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (facilities) {
        final inspections = inspectionsAsync.valueOrNull ?? <Inspection>[];
        final mandals = mandalsAsync.valueOrNull ?? [];

        // Find latest inspection per facility
        final latestByFacility = <String, Inspection>{};
        for (final i in inspections) {
          final existing = latestByFacility[i.facilityId];
          if (existing == null || i.datetime.isAfter(existing.datetime)) {
            latestByFacility[i.facilityId] = i;
          }
        }

        // Non-compliant: latest grade <= average
        var nonCompliant = facilities.where((f) {
          final latest = latestByFacility[f.id];
          if (latest == null) return false;
          return latest.grade == Grade.critical ||
              latest.grade == Grade.poor ||
              latest.grade == Grade.average;
        }).toList();

        if (_mandalFilter != null) {
          nonCompliant = nonCompliant
              .where((f) => f.mandalId == _mandalFilter)
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('${nonCompliant.length} non-compliant facilities',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FimmsColors.textMuted)),
                  const Spacer(),
                  DropdownButton<String?>(
                    value: _mandalFilter,
                    hint: const Text('All Mandals',
                        style: TextStyle(fontSize: 13)),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Mandals')),
                      ...mandals.map((m) => DropdownMenuItem(
                          value: m.id, child: Text(m.name))),
                    ],
                    onChanged: (v) => setState(() => _mandalFilter = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: nonCompliant.isEmpty
                  ? const Center(
                      child: Text('No non-compliant facilities',
                          style: TextStyle(color: FimmsColors.textMuted)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: nonCompliant.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final f = nonCompliant[index];
                        final latest = latestByFacility[f.id]!;
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side:
                                const BorderSide(color: FimmsColors.outline),
                          ),
                          child: ListTile(
                            title: Text(f.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${f.mandalId} · ${DateFormat('dd MMM').format(latest.datetime)} · '
                              'Score: ${latest.totalScore.round()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: GradeChip(
                                grade: latest.grade, compact: true),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
