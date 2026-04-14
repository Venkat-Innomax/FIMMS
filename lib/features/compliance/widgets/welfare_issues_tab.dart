import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/inspection.dart';

// ---------------------------------------------------------------------------
// Mock issue data derived from inspections
// ---------------------------------------------------------------------------

class _Issue {
  final String id;
  final String facilityName;
  final String facilityId;
  final String description;
  final String severity;
  final DateTime raisedOn;
  final bool resolved;

  const _Issue({
    required this.id,
    required this.facilityName,
    required this.facilityId,
    required this.description,
    required this.severity,
    required this.raisedOn,
    this.resolved = false,
  });
}

List<_Issue> _issuesFromInspections(
    List<Inspection> inspections, Map<String, String> facilityNames) {
  final issues = <_Issue>[];
  for (final i in inspections) {
    final name = facilityNames[i.facilityId] ?? i.facilityId;
    if (i.urgentFlag) {
      issues.add(_Issue(
        id: '${i.id}-urgent',
        facilityName: name,
        facilityId: i.facilityId,
        description: 'Urgent flag raised during inspection — immediate action needed',
        severity: 'Critical',
        raisedOn: i.datetime,
      ));
    }
    if (i.totalScore < 50) {
      issues.add(_Issue(
        id: '${i.id}-score',
        facilityName: name,
        facilityId: i.facilityId,
        description: 'Low inspection score (${i.totalScore.toStringAsFixed(0)}/100) — compliance review required',
        severity: i.totalScore < 35 ? 'Major' : 'Minor',
        raisedOn: i.datetime,
      ));
    }
  }
  // Fill with demo issues if empty
  if (issues.isEmpty) {
    issues.addAll([
      _Issue(
        id: 'demo-1',
        facilityName: 'SW Boys Hostel, Bhongir',
        facilityId: 'demo',
        description: 'Kitchen hygiene standards not met — cleaning schedule not followed',
        severity: 'Major',
        raisedOn: DateTime.now().subtract(const Duration(days: 5)),
      ),
      _Issue(
        id: 'demo-2',
        facilityName: 'BC Girls Hostel, Ramannapeta',
        facilityId: 'demo',
        description: 'Drinking water supply interrupted — tank cleaning overdue',
        severity: 'Critical',
        raisedOn: DateTime.now().subtract(const Duration(days: 3)),
      ),
      _Issue(
        id: 'demo-3',
        facilityName: 'PHC Mothkur',
        facilityId: 'demo',
        description: 'Medical stock register not maintained — monthly audit required',
        severity: 'Minor',
        raisedOn: DateTime.now().subtract(const Duration(days: 8)),
        resolved: true,
      ),
    ]);
  }
  return issues;
}

// ---------------------------------------------------------------------------
// Tab widget
// ---------------------------------------------------------------------------

class WelfareIssuesTab extends ConsumerStatefulWidget {
  const WelfareIssuesTab({super.key});

  @override
  ConsumerState<WelfareIssuesTab> createState() => _WelfareIssuesTabState();
}

class _WelfareIssuesTabState extends ConsumerState<WelfareIssuesTab> {
  String _filter = 'Open'; // Open | All

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
              const Text('Show:',
                  style: TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
              const SizedBox(width: 10),
              for (final label in ['Open', 'All'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _filter == label,
                    onSelected: (_) => setState(() => _filter = label),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: _filter == label
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
              final nameMap = {for (final f in facilities) f.id: f.name};
              return inspectionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildList(
                    _issuesFromInspections([], nameMap), nameMap),
                data: (inspections) => _buildList(
                    _issuesFromInspections(inspections, nameMap), nameMap),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<_Issue> allIssues, Map<String, String> nameMap) {
    final issues = _filter == 'Open'
        ? allIssues.where((i) => !i.resolved).toList()
        : allIssues;

    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: FimmsColors.success),
            const SizedBox(height: 12),
            Text(
              _filter == 'Open' ? 'No open issues!' : 'No issues found',
              style: const TextStyle(color: FimmsColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: issues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final issue = issues[index];
        return _IssueCard(
          issue: issue,
          onResolved: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Issue marked resolved (demo)'),
                backgroundColor: FimmsColors.success,
              ),
            );
          },
        );
      },
    );
  }
}

class _IssueCard extends StatelessWidget {
  final _Issue issue;
  final VoidCallback onResolved;
  const _IssueCard({required this.issue, required this.onResolved});

  Color get _severityColor => switch (issue.severity) {
        'Critical' => FimmsColors.danger,
        'Major' => FimmsColors.warning,
        _ => FimmsColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final daysOpen = DateTime.now().difference(issue.raisedOn).inDays;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: issue.resolved
            ? FimmsColors.surface
            : FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: issue.resolved
              ? FimmsColors.outline
              : _severityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SeverityChip(
                  severity: issue.severity, resolved: issue.resolved),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.facilityName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                issue.resolved
                    ? 'Resolved'
                    : '$daysOpen day${daysOpen != 1 ? 's' : ''} open',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      issue.resolved ? FimmsColors.success : FimmsColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            issue.description,
            style: const TextStyle(
                fontSize: 12.5, color: FimmsColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 11, color: FimmsColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Raised ${DateFormat('d MMM yyyy').format(issue.raisedOn)}',
                style: const TextStyle(
                    fontSize: 11, color: FimmsColors.textMuted),
              ),
              const Spacer(),
              if (!issue.resolved)
                OutlinedButton(
                  onPressed: onResolved,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                    foregroundColor: FimmsColors.success,
                    side: BorderSide(
                        color: FimmsColors.success.withValues(alpha: 0.5)),
                  ),
                  child: const Text('Mark Resolved'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String severity;
  final bool resolved;
  const _SeverityChip({required this.severity, required this.resolved});

  @override
  Widget build(BuildContext context) {
    final color = resolved
        ? FimmsColors.success
        : switch (severity) {
            'Critical' => FimmsColors.danger,
            'Major' => FimmsColors.warning,
            _ => FimmsColors.textMuted,
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        resolved ? 'Resolved' : severity,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
