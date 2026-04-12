import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../shared_widgets/grade_chip.dart';
import '../../shared_widgets/responsive_scaffold.dart';

class FacilityDetailPage extends ConsumerWidget {
  final String facilityId;
  const FacilityDetailPage({super.key, required this.facilityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilityRepo = ref.read(facilityRepositoryProvider);
    final inspectionRepo = ref.read(inspectionRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/collector'),
        ),
        title: const Text('Facility Detail'),
      ),
      body: FutureBuilder<Facility?>(
        future: facilityRepo.facilityById(facilityId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final facility = snap.data;
          if (facility == null) {
            return const Center(child: Text('Facility not found'));
          }
          return FutureBuilder<List<Inspection>>(
            future: inspectionRepo.loadAll(),
            builder: (context, isnap) {
              if (!isnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final history = isnap.data!
                  .where((i) => i.facilityId == facility.id)
                  .toList()
                ..sort((a, b) => b.datetime.compareTo(a.datetime));
              return _Content(
                facility: facility,
                history: history,
                userRepo: userRepo,
              );
            },
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final Facility facility;
  final List<Inspection> history;
  final UserRepository userRepo;

  const _Content({
    required this.facility,
    required this.history,
    required this.userRepo,
  });

  @override
  Widget build(BuildContext context) {
    final latest = history.isNotEmpty ? history.first : null;
    final dateFmt = DateFormat('EEE, d MMM yyyy · h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FimmsBrandMark(),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FimmsColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    facility.type.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: FimmsColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  facility.subTypeLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: FimmsColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              facility.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${facility.village}, ${_cap(facility.mandalId)} Mandal',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: FimmsColors.textMuted),
            ),
            const SizedBox(height: 20),
            if (latest != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FimmsColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FimmsColors.outline),
                ),
                child: Row(
                  children: [
                    GradeChip(
                      grade: latest.grade,
                      scoreOutOf100: latest.totalScore,
                    ),
                    const SizedBox(width: 12),
                    if (latest.urgentFlag) const UrgentBadge(),
                    const Spacer(),
                    Text(
                      dateFmt.format(latest.datetime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: FimmsColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Inspection history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              Text(
                'No inspections recorded yet.',
                style: TextStyle(
                  color: FimmsColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              for (final insp in history) _HistoryRow(
                inspection: insp,
                userRepo: userRepo,
              ),
          ],
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _HistoryRow extends StatelessWidget {
  final Inspection inspection;
  final UserRepository userRepo;

  const _HistoryRow({required this.inspection, required this.userRepo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FimmsColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FimmsColors.outline),
        ),
        child: Row(
          children: [
            GradeChip(
              grade: inspection.grade,
              scoreOutOf100: inspection.totalScore,
              compact: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d MMM yyyy').format(inspection.datetime),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'GPS ${inspection.gps.latitude.toStringAsFixed(4)}, '
                    '${inspection.gps.longitude.toStringAsFixed(4)} · '
                    'Geo-fence ${inspection.geofencePass ? "PASS" : "FAIL"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: FimmsColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (inspection.urgentFlag) const UrgentBadge(),
          ],
        ),
      ),
    );
  }
}
