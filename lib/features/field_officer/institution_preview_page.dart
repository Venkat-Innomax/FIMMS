import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/repositories/facility_repository.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../models/facility.dart';
import '../../models/inspection.dart';
import '../shared_widgets/grade_chip.dart';

class InstitutionPreviewPage extends ConsumerWidget {
  final String facilityId;
  const InstitutionPreviewPage({super.key, required this.facilityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return facilitiesAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error loading facility: $e'))),
      data: (facilities) {
        final facility = facilities.cast<Facility?>().firstWhere(
              (f) => f?.id == facilityId,
              orElse: () => null,
            );
        if (facility == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Facility not found')),
          );
        }
        return inspectionsAsync.when(
          loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator())),
          error: (e, _) => _buildPage(context, facility, null),
          data: (inspections) {
            final history = inspections
                .where((i) => i.facilityId == facilityId)
                .toList()
              ..sort((a, b) => b.datetime.compareTo(a.datetime));
            final latest = history.isNotEmpty ? history.first : null;
            return _buildPage(context, facility, latest,
                history: history);
          },
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    Facility facility,
    Inspection? latest, {
    List<Inspection> history = const [],
  }) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [FimmsColors.primary, FimmsColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          facility.type == FacilityType.hostel
                              ? Icons.house_outlined
                              : Icons.local_hospital_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facility.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              facility.subTypeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _WhiteChip(
                          icon: Icons.location_on_outlined,
                          text: '${_cap(facility.mandalId)} Mandal'),
                      _WhiteChip(
                          icon: Icons.place_outlined,
                          text: facility.village.isNotEmpty
                              ? facility.village
                              : 'Location TBD'),
                      if (facility.gender != null)
                        _WhiteChip(
                            icon: Icons.people_outline,
                            text: facility.gender!),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Last inspection
            _InfoSection(
              title: 'Last Inspection',
              icon: Icons.history,
              child: latest == null
                  ? const _NoDataRow(text: 'No inspection on record')
                  : Row(
                      children: [
                        GradeChip(
                          grade: latest.grade,
                          scoreOutOf100: latest.totalScore,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('d MMM yyyy · h:mm a')
                                    .format(latest.datetime),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              if (latest.urgentFlag)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: UrgentBadge(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            // Special officer
            _InfoSection(
              title: 'In-charge Officer',
              icon: Icons.badge_outlined,
              child: facility.specialOfficerName != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.specialOfficerName!,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (facility.specialOfficerPhone != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 13,
                                    color: FimmsColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  facility.specialOfficerPhone!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: FimmsColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : const _NoDataRow(text: 'Not assigned'),
            ),

            const SizedBox(height: 12),

            // Department
            if (facility.department != null)
              _InfoSection(
                title: 'Department',
                icon: Icons.account_balance_outlined,
                child: Text(
                  facility.department!,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),

            if (facility.department != null) const SizedBox(height: 12),

            // Inspection history (last 3)
            if (history.length > 1) ...[
              _InfoSection(
                title: 'Inspection History (Recent)',
                icon: Icons.timeline,
                child: Column(
                  children: [
                    for (final i in history.skip(1).take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            GradeChip(
                              grade: i.grade,
                              scoreOutOf100: i.totalScore,
                              compact: true,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('d MMM yyyy').format(i.datetime),
                              style: const TextStyle(
                                  fontSize: 12, color: FimmsColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // GPS coordinates
            _InfoSection(
              title: 'Location Coordinates',
              icon: Icons.gps_fixed,
              child: Text(
                '${facility.location.latitude.toStringAsFixed(5)}, '
                '${facility.location.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: FimmsColors.textMuted),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () =>
                context.go('/officer/inspect/$facilityId'),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Start Inspection'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _WhiteChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _WhiteChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _InfoSection(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: FimmsColors.textMuted),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: FimmsColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _NoDataRow extends StatelessWidget {
  final String text;
  const _NoDataRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 12, fontStyle: FontStyle.italic, color: FimmsColors.textMuted),
    );
  }
}
