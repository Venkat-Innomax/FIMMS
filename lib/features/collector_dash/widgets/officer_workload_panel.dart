import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../../models/user.dart';
import '../../shared_widgets/empty_state.dart';
import '../../shared_widgets/grade_chip.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _OfficerEntry {
  final String officerId;
  final User? officer;
  final List<Inspection> inspections; // sorted newest first
  final double avgScore;
  final DateTime? lastDate;
  final Map<Grade, int> gradeCounts;
  final int urgentCount;

  _OfficerEntry({
    required this.officerId,
    required this.officer,
    required this.inspections,
  })  : avgScore = inspections.isEmpty
            ? 0.0
            : inspections.map((i) => i.totalScore).reduce((a, b) => a + b) /
                inspections.length,
        lastDate = inspections.isNotEmpty ? inspections.first.datetime : null,
        gradeCounts = _buildGradeCounts(inspections),
        urgentCount = inspections.where((i) => i.urgentFlag).length;

  static Map<Grade, int> _buildGradeCounts(List<Inspection> insps) {
    final m = <Grade, int>{};
    for (final i in insps) {
      m[i.grade] = (m[i.grade] ?? 0) + 1;
    }
    return m;
  }

  Grade get avgGrade => GradeX.fromScore(avgScore);

  String get initials {
    final name = officer?.name ?? officerId;
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }
}

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

class OfficerWorkloadPanel extends StatefulWidget {
  final List<Inspection> inspections;
  final Map<String, User> userMap;
  final Map<String, Facility> facilityMap;

  const OfficerWorkloadPanel({
    super.key,
    required this.inspections,
    required this.userMap,
    required this.facilityMap,
  });

  @override
  State<OfficerWorkloadPanel> createState() => _OfficerWorkloadPanelState();
}

class _OfficerWorkloadPanelState extends State<OfficerWorkloadPanel> {
  String _sortBy = 'inspections';
  _OfficerEntry? _selected;

  List<_OfficerEntry> _buildEntries() {
    final byOfficer = <String, List<Inspection>>{};
    for (final insp in widget.inspections) {
      byOfficer.putIfAbsent(insp.officerId, () => []).add(insp);
    }

    var entries = byOfficer.entries.map((e) {
      final insps = e.value..sort((a, b) => b.datetime.compareTo(a.datetime));
      return _OfficerEntry(
        officerId: e.key,
        officer: widget.userMap[e.key],
        inspections: insps,
      );
    }).toList();

    switch (_sortBy) {
      case 'score':
        entries.sort((a, b) => b.avgScore.compareTo(a.avgScore));
      case 'name':
        entries.sort(
            (a, b) => (a.officer?.name ?? '').compareTo(b.officer?.name ?? ''));
      default:
        entries.sort(
            (a, b) => b.inspections.length.compareTo(a.inspections.length));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No inspection data available',
      );
    }

    // Keep selected in sync after sort
    final selected = _selected == null
        ? null
        : entries.firstWhere(
            (e) => e.officerId == _selected!.officerId,
            orElse: () => entries.first,
          );

    final showDetail = selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(
          officerCount: entries.length,
          totalInspections: widget.inspections.length,
          sortBy: _sortBy,
          onSortChanged: (v) => setState(() => _sortBy = v),
          selectedName: selected?.officer?.name,
          onClearSelection: () => setState(() => _selected = null),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Officer card list ──────────────────────────────────────
              if (showDetail)
                SizedBox(
                  width: 300,
                  child: _OfficerList(
                    entries: entries,
                    selected: selected!,
                    onSelect: (e) => setState(() => _selected = e),
                    compact: true,
                  ),
                )
              else
                Expanded(
                  child: _OfficerGrid(
                    entries: entries,
                    onSelect: (e) => setState(() => _selected = e),
                  ),
                ),
              // ── Detail panel ───────────────────────────────────────────
              if (showDetail) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailPanel(
                    entry: selected!,
                    facilityMap: widget.facilityMap,
                    onClose: () => setState(() => _selected = null),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final int officerCount;
  final int totalInspections;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final String? selectedName;
  final VoidCallback onClearSelection;

  const _TopBar({
    required this.officerCount,
    required this.totalInspections,
    required this.sortBy,
    required this.onSortChanged,
    required this.selectedName,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (selectedName != null) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            onPressed: onClearSelection,
            tooltip: 'Back to all officers',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          Text(
            selectedName!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$officerCount Officers',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                '$totalInspections total inspections',
                style: const TextStyle(
                    fontSize: 11, color: FimmsColors.textMuted),
              ),
            ],
          ),
        ],
        const Spacer(),
        const Text('Sort  ',
            style: TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
        DropdownButton<String>(
          value: sortBy,
          underline: const SizedBox.shrink(),
          isDense: true,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FimmsColors.primary),
          items: const [
            DropdownMenuItem(
                value: 'inspections', child: Text('Most Inspections')),
            DropdownMenuItem(value: 'score', child: Text('Avg Score')),
            DropdownMenuItem(value: 'name', child: Text('Name')),
          ],
          onChanged: (v) => v != null ? onSortChanged(v) : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Full-width grid (no selection yet)
// ---------------------------------------------------------------------------

class _OfficerGrid extends StatelessWidget {
  final List<_OfficerEntry> entries;
  final ValueChanged<_OfficerEntry> onSelect;

  const _OfficerGrid({required this.entries, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 210,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) =>
          _OfficerGridCard(entry: entries[i], onTap: () => onSelect(entries[i])),
    );
  }
}

class _OfficerGridCard extends StatelessWidget {
  final _OfficerEntry entry;
  final VoidCallback onTap;

  const _OfficerGridCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grade = entry.avgGrade;
    final lastFmt = entry.lastDate != null
        ? DateFormat('dd MMM yyyy').format(entry.lastDate!)
        : '—';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Coloured top accent bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 4, color: grade.color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name row
                  Row(
                    children: [
                      _Avatar(initials: entry.initials, grade: grade, radius: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.officer?.name ?? entry.officerId,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              entry.officer?.designation ?? 'Field Officer',
                              style: const TextStyle(
                                  fontSize: 11, color: FimmsColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Stats row
                  Row(
                    children: [
                      _StatBox(
                        value: '${entry.inspections.length}',
                        label: 'Inspections',
                        color: FimmsColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _StatBox(
                        value: entry.avgScore.toStringAsFixed(1),
                        label: 'Avg Score',
                        color: grade.color,
                      ),
                      const SizedBox(width: 8),
                      _StatBox(
                        value: '${entry.urgentCount}',
                        label: 'Urgent',
                        color: entry.urgentCount > 0
                            ? Colors.red
                            : FimmsColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Grade distribution bar
                  _GradeBar(gradeCounts: entry.gradeCounts,
                      total: entry.inspections.length),
                  const SizedBox(height: 8),
                  // Last inspection date + chevron
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 11, color: FimmsColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Last: $lastFmt',
                        style: const TextStyle(
                            fontSize: 11, color: FimmsColors.textMuted),
                      ),
                      const Spacer(),
                      Text(
                        'View Details',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: FimmsColors.primary),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right,
                          size: 16, color: FimmsColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact list (shown when detail panel is open)
// ---------------------------------------------------------------------------

class _OfficerList extends StatelessWidget {
  final List<_OfficerEntry> entries;
  final _OfficerEntry selected;
  final ValueChanged<_OfficerEntry> onSelect;
  final bool compact;

  const _OfficerList({
    required this.entries,
    required this.selected,
    required this.onSelect,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(right: 4, bottom: 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final e = entries[i];
        final isSelected = e.officerId == selected.officerId;
        return _CompactOfficerCard(
          entry: e,
          isSelected: isSelected,
          onTap: () => onSelect(e),
        );
      },
    );
  }
}

class _CompactOfficerCard extends StatelessWidget {
  final _OfficerEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactOfficerCard({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final grade = entry.avgGrade;

    return Material(
      color: isSelected
          ? FimmsColors.primary.withValues(alpha: 0.07)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? FimmsColors.primary : FimmsColors.outline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _Avatar(initials: entry.initials, grade: grade, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.officer?.name ?? entry.officerId,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? FimmsColors.primary
                            : FimmsColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${entry.inspections.length} inspections  •  '
                      '${entry.avgScore.toStringAsFixed(0)} avg',
                      style: const TextStyle(
                          fontSize: 10, color: FimmsColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: grade.color, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail panel
// ---------------------------------------------------------------------------

class _DetailPanel extends StatelessWidget {
  final _OfficerEntry entry;
  final Map<String, Facility> facilityMap;
  final VoidCallback onClose;

  const _DetailPanel({
    required this.entry,
    required this.facilityMap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final grade = entry.avgGrade;
    final compliantCount = (entry.gradeCounts[Grade.excellent] ?? 0) +
        (entry.gradeCounts[Grade.good] ?? 0);
    final complianceRate = entry.inspections.isEmpty
        ? 0.0
        : compliantCount / entry.inspections.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  grade.color.withValues(alpha: 0.12),
                  grade.color.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: FimmsColors.outline),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(initials: entry.initials, grade: grade, radius: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.officer?.name ?? entry.officerId,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.officer?.designation ?? 'Field Officer',
                        style: const TextStyle(
                            fontSize: 12, color: FimmsColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      GradeChip(grade: grade),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // ── Summary stat cards ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _DetailStat(
                  icon: Icons.assignment_outlined,
                  label: 'Total',
                  value: '${entry.inspections.length}',
                  color: FimmsColors.primary,
                ),
                const SizedBox(width: 8),
                _DetailStat(
                  icon: Icons.star_outline,
                  label: 'Avg Score',
                  value: entry.avgScore.toStringAsFixed(1),
                  color: grade.color,
                ),
                const SizedBox(width: 8),
                _DetailStat(
                  icon: Icons.check_circle_outline,
                  label: 'Compliant',
                  value: '${(complianceRate * 100).toStringAsFixed(0)}%',
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                _DetailStat(
                  icon: Icons.flag_outlined,
                  label: 'Urgent',
                  value: '${entry.urgentCount}',
                  color: entry.urgentCount > 0 ? Colors.red : FimmsColors.textMuted,
                ),
              ],
            ),
          ),
          // ── Grade distribution ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grade Distribution',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FimmsColors.textMuted),
                ),
                const SizedBox(height: 8),
                _GradeDistributionBar(
                  gradeCounts: entry.gradeCounts,
                  total: entry.inspections.length,
                ),
                const SizedBox(height: 6),
                _GradeLegendRow(gradeCounts: entry.gradeCounts),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Inspection history list ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Inspection History (${entry.inspections.length})',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: entry.inspections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _InspectionCard(
                inspection: entry.inspections[i],
                facility: facilityMap[entry.inspections[i].facilityId],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: FimmsColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeDistributionBar extends StatelessWidget {
  final Map<Grade, int> gradeCounts;
  final int total;

  const _GradeDistributionBar(
      {required this.gradeCounts, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    const order = [
      Grade.excellent,
      Grade.good,
      Grade.average,
      Grade.poor,
      Grade.critical,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: order.map((g) {
          final count = gradeCounts[g] ?? 0;
          if (count == 0) return const SizedBox.shrink();
          return Flexible(
            flex: count,
            child: Container(
              height: 12,
              color: g.color,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GradeLegendRow extends StatelessWidget {
  final Map<Grade, int> gradeCounts;

  const _GradeLegendRow({required this.gradeCounts});

  @override
  Widget build(BuildContext context) {
    const order = [
      Grade.excellent,
      Grade.good,
      Grade.average,
      Grade.poor,
      Grade.critical,
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: order
          .where((g) => (gradeCounts[g] ?? 0) > 0)
          .map((g) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: g.color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(
                    '${g.label} (${gradeCounts[g]})',
                    style: const TextStyle(
                        fontSize: 10, color: FimmsColors.textMuted),
                  ),
                ],
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Inspection card (used inside detail panel)
// ---------------------------------------------------------------------------

class _InspectionCard extends StatelessWidget {
  final Inspection inspection;
  final Facility? facility;

  const _InspectionCard({required this.inspection, this.facility});

  @override
  Widget build(BuildContext context) {
    final grade = inspection.grade;
    final dateFmt =
        DateFormat('dd MMM yyyy, hh:mm a').format(inspection.datetime);
    final score = inspection.totalScore.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: grade.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: grade.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: grade.color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: grade.color,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 8,
                    color: grade.color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility?.name ?? inspection.facilityId,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: dateFmt,
                ),
                if (facility != null) ...[
                  const SizedBox(height: 2),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text:
                        '${facility!.mandalId.replaceAll('_', ' ')}  •  ${facility!.subTypeLabel}',
                  ),
                ],
                const SizedBox(height: 6),
                // Score progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: inspection.totalScore / 100,
                    minHeight: 4,
                    backgroundColor: FimmsColors.outline,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(grade.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GradeChip(grade: grade),
              const SizedBox(height: 4),
              _StatusPill(status: inspection.status),
              if (inspection.urgentFlag) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 9, color: Colors.red),
                      SizedBox(width: 3),
                      Text(
                        'Urgent',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: FimmsColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(fontSize: 11, color: FimmsColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  final String initials;
  final Grade grade;
  final double radius;

  const _Avatar(
      {required this.initials, required this.grade, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: grade.color.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.55,
          fontWeight: FontWeight.w800,
          color: grade.color,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 9, color: FimmsColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeBar extends StatelessWidget {
  final Map<Grade, int> gradeCounts;
  final int total;

  const _GradeBar({required this.gradeCounts, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    const order = [
      Grade.excellent,
      Grade.good,
      Grade.average,
      Grade.poor,
      Grade.critical,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: order.map((g) {
          final count = gradeCounts[g] ?? 0;
          if (count == 0) return const SizedBox.shrink();
          return Flexible(
            flex: count,
            child: Container(height: 6, color: g.color),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final InspectionStatus status;

  const _StatusPill({required this.status});

  Color get _color {
    switch (status) {
      case InspectionStatus.approved:
        return Colors.teal;
      case InspectionStatus.rejected:
        return Colors.red;
      case InspectionStatus.underReview:
        return Colors.orange;
      case InspectionStatus.reinspectionOrdered:
        return Colors.deepOrange;
      case InspectionStatus.draft:
        return Colors.grey;
      case InspectionStatus.submitted:
        return FimmsColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}
