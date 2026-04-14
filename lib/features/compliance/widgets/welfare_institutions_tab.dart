import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../../services/mock_auth_service.dart';

class WelfareInstitutionsTab extends ConsumerWidget {
  const WelfareInstitutionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return facilitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allFacilities) {
        // Show facilities linked to this welfare officer's facility/mandal.
        final myFacilities = user?.facilityId != null
            ? allFacilities
                .where((f) => f.id == user!.facilityId)
                .toList()
            : user?.mandalId != null
                ? allFacilities
                    .where((f) => f.mandalId == user!.mandalId)
                    .toList()
                : allFacilities.take(6).toList();

        if (myFacilities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.house_outlined, size: 48, color: FimmsColors.textMuted),
                SizedBox(height: 12),
                Text('No institutions assigned',
                    style: TextStyle(color: FimmsColors.textMuted)),
              ],
            ),
          );
        }

        return inspectionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildList(context, myFacilities, {}),
          data: (inspections) {
            final latest = <String, Inspection>{};
            for (final i in inspections) {
              final ex = latest[i.facilityId];
              if (ex == null || i.datetime.isAfter(ex.datetime)) {
                latest[i.facilityId] = i;
              }
            }
            return _buildList(context, myFacilities, latest);
          },
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Facility> facilities,
    Map<String, Inspection> latestByFacility,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: facilities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final f = facilities[index];
        final latest = latestByFacility[f.id];
        return _InstitutionCard(facility: f, latestInspection: latest);
      },
    );
  }
}

class _InstitutionCard extends StatefulWidget {
  final Facility facility;
  final Inspection? latestInspection;
  const _InstitutionCard({required this.facility, this.latestInspection});

  @override
  State<_InstitutionCard> createState() => _InstitutionCardState();
}

class _InstitutionCardState extends State<_InstitutionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.facility;
    final latest = widget.latestInspection;
    final complianceStatus = _complianceStatus(latest);

    return Material(
      color: FimmsColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: FimmsColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FimmsColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      f.type == FacilityType.hostel
                          ? Icons.house_outlined
                          : Icons.local_hospital_outlined,
                      color: FimmsColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${f.subTypeLabel} · ${_cap(f.mandalId)} Mandal',
                          style: const TextStyle(
                              fontSize: 11, color: FimmsColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ComplianceBadge(status: complianceStatus),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: FimmsColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.history,
                    label: 'Last Inspection',
                    value: latest == null
                        ? 'No inspection on record'
                        : DateFormat('d MMM yyyy · h:mm a')
                            .format(latest.datetime),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.score,
                    label: 'Score',
                    value: latest == null
                        ? '—'
                        : '${latest.totalScore.toStringAsFixed(1)} / 100',
                  ),
                  if (f.specialOfficerName != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: 'In-charge',
                      value: f.specialOfficerName!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('View Inspection Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _complianceStatus(Inspection? latest) {
    if (latest == null) return 'Uninspected';
    if (latest.urgentFlag) return 'Critical';
    if (latest.totalScore >= 70) return 'Compliant';
    if (latest.totalScore >= 50) return 'Partial';
    return 'Non-Compliant';
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ComplianceBadge extends StatelessWidget {
  final String status;
  const _ComplianceBadge({required this.status});

  Color get _color => switch (status) {
        'Compliant' => FimmsColors.success,
        'Partial' => FimmsColors.warning,
        'Non-Compliant' => FimmsColors.danger,
        'Critical' => FimmsColors.danger,
        _ => FimmsColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FimmsColors.textMuted),
        const SizedBox(width: 6),
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: FimmsColors.textMuted)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
