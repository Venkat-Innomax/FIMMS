import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../shared_widgets/grade_chip.dart';

class FacilityListView extends ConsumerStatefulWidget {
  final String mandalId;
  const FacilityListView({super.key, required this.mandalId});

  @override
  ConsumerState<FacilityListView> createState() => _FacilityListViewState();
}

class _FacilityListViewState extends ConsumerState<FacilityListView> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);
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

        var mandalFacilities = facilities
            .where((f) => f.mandalId == widget.mandalId)
            .toList();

        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          mandalFacilities = mandalFacilities
              .where((f) =>
                  f.name.toLowerCase().contains(q) ||
                  f.village.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search facilities...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mandalFacilities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final f = mandalFacilities[index];
                  final latest = latestByFacility[f.id];

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: FimmsColors.outline),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        f.type == FacilityType.hostel
                            ? Icons.hotel
                            : Icons.local_hospital,
                        color: f.type == FacilityType.hostel
                            ? Colors.purple
                            : Colors.teal,
                        size: 20,
                      ),
                      title: Text(f.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        latest != null
                            ? '${f.village} · Score: ${latest.totalScore.round()} · '
                                '${DateFormat('dd MMM').format(latest.datetime)}'
                            : '${f.village} · Not inspected',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: latest != null
                          ? GradeChip(grade: latest.grade, compact: true)
                          : null,
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
