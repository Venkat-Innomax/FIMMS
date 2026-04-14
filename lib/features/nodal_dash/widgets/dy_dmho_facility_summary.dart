import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';

class DyDmhoFacilitySummary extends ConsumerStatefulWidget {
  const DyDmhoFacilitySummary({super.key});

  @override
  ConsumerState<DyDmhoFacilitySummary> createState() =>
      _DyDmhoFacilitySummaryState();
}

class _DyDmhoFacilitySummaryState
    extends ConsumerState<DyDmhoFacilitySummary> {
  String _filterSubType = 'All'; // All | DH | CHC | PHC | UPHC

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: FimmsColors.surface,
          child: Row(
            children: [
              const Text('Facility Type: ',
                  style: TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
              const SizedBox(width: 4),
              for (final t in ['All', 'DH', 'CHC', 'PHC', 'UPHC'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: _filterSubType == t,
                    onSelected: (_) =>
                        setState(() => _filterSubType = t),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: _filterSubType == t
                          ? Colors.white
                          : FimmsColors.textMuted,
                    ),
                    selectedColor: FimmsColors.primary,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: facilitiesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (facilities) {
              final hospitals = facilities
                  .where((f) => f.type == FacilityType.hospital)
                  .where((f) =>
                      _filterSubType == 'All' ||
                      f.subType.toUpperCase() == _filterSubType)
                  .toList();

              return inspectionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildList(context, hospitals, {}),
                data: (inspections) {
                  final latest = <String, Inspection>{};
                  for (final i in inspections) {
                    final ex = latest[i.facilityId];
                    if (ex == null ||
                        i.datetime.isAfter(ex.datetime)) {
                      latest[i.facilityId] = i;
                    }
                  }
                  return _buildList(context, hospitals, latest);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Facility> facilities,
    Map<String, Inspection> latestMap,
  ) {
    if (facilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_hospital_outlined,
                size: 48, color: FimmsColors.textMuted),
            const SizedBox(height: 12),
            Text(
              _filterSubType == 'All'
                  ? 'No hospital facilities found'
                  : 'No $_filterSubType facilities found',
              style: const TextStyle(color: FimmsColors.textMuted),
            ),
          ],
        ),
      );
    }

    // Summary stats
    final inspectedCount =
        facilities.where((f) => latestMap.containsKey(f.id)).length;
    final criticalCount = facilities
        .where((f) => latestMap[f.id]?.urgentFlag == true)
        .length;
    final avgScore = facilities.isEmpty
        ? 0.0
        : facilities
                .map((f) => latestMap[f.id]?.totalScore ?? 0.0)
                .reduce((a, b) => a + b) /
            facilities.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary chips
        Row(
          children: [
            _StatBadge(
                label: 'Total',
                value: '${facilities.length}',
                color: FimmsColors.primary),
            const SizedBox(width: 8),
            _StatBadge(
                label: 'Inspected',
                value: '$inspectedCount',
                color: FimmsColors.success),
            const SizedBox(width: 8),
            _StatBadge(
                label: 'Avg Score',
                value: avgScore.toStringAsFixed(0),
                color: FimmsColors.warning),
            const SizedBox(width: 8),
            _StatBadge(
                label: 'Critical',
                value: '$criticalCount',
                color: FimmsColors.danger),
          ],
        ),
        const SizedBox(height: 16),

        // Facility cards
        for (final f in facilities) ...[
          _FacilityCard(facility: f, inspection: latestMap[f.id]),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  final Inspection? inspection;
  const _FacilityCard({required this.facility, this.inspection});

  @override
  Widget build(BuildContext context) {
    final hasInspection = inspection != null;
    final isUrgent = inspection?.urgentFlag == true;
    final score = inspection?.totalScore ?? 0.0;
    final borderColor = isUrgent
        ? FimmsColors.danger.withValues(alpha: 0.4)
        : FimmsColors.outline;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FimmsColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  facility.subType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: FimmsColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facility.name,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${_cap(facility.mandalId)} Mandal · ${facility.village}',
                      style: const TextStyle(
                          fontSize: 11, color: FimmsColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isUrgent)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.warning_amber,
                      color: FimmsColors.danger, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasInspection) ...[
            Row(
              children: [
                _ScoreBar(score: score),
                const SizedBox(width: 12),
                Text(
                  DateFormat('d MMM yyyy').format(inspection!.datetime),
                  style: const TextStyle(
                      fontSize: 11, color: FimmsColors.textMuted),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Icon(Icons.hourglass_empty,
                    size: 14, color: FimmsColors.textMuted),
                const SizedBox(width: 4),
                const Text('Not yet inspected',
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: FimmsColors.textMuted)),
              ],
            ),

          if (facility.specialOfficerName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.badge_outlined,
                    size: 12, color: FimmsColors.textMuted),
                const SizedBox(width: 4),
                Text(facility.specialOfficerName!,
                    style: const TextStyle(
                        fontSize: 11, color: FimmsColors.textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ScoreBar extends StatelessWidget {
  final double score;
  const _ScoreBar({required this.score});

  Color get _color {
    if (score >= 85) return FimmsColors.success;
    if (score >= 70) return FimmsColors.primary;
    if (score >= 50) return FimmsColors.warning;
    if (score >= 35) return Colors.deepOrange;
    return FimmsColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: FimmsColors.outline,
            color: _color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${score.toStringAsFixed(0)}/100',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: FimmsColors.textMuted)),
        ],
      ),
    );
  }
}
