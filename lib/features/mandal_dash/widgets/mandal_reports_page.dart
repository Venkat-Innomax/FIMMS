import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/export_utils.dart';
import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../../models/user.dart';

// ---------------------------------------------------------------------------
// Mock monthly report data
// ---------------------------------------------------------------------------

class _MonthRow {
  final String month;
  final int total;
  final int completed;
  final int issueCount;
  final int complaintCount;

  const _MonthRow({
    required this.month,
    required this.total,
    required this.completed,
    required this.issueCount,
    required this.complaintCount,
  });

  double get completionPct => total == 0 ? 0 : (completed / total) * 100;
}

const _mockMonthly = [
  _MonthRow(month: 'Apr 2024', total: 22, completed: 20, issueCount: 14, complaintCount: 3),
  _MonthRow(month: 'Mar 2024', total: 22, completed: 18, issueCount: 11, complaintCount: 5),
  _MonthRow(month: 'Feb 2024', total: 20, completed: 16, issueCount: 9, complaintCount: 2),
  _MonthRow(month: 'Jan 2024', total: 20, completed: 19, issueCount: 7, complaintCount: 4),
  _MonthRow(month: 'Dec 2023', total: 18, completed: 15, issueCount: 10, complaintCount: 3),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MandalReportsPage extends ConsumerStatefulWidget {
  final String mandalId;
  const MandalReportsPage({super.key, required this.mandalId});

  @override
  ConsumerState<MandalReportsPage> createState() =>
      _MandalReportsPageState();
}

class _MandalReportsPageState extends ConsumerState<MandalReportsPage> {
  bool _exporting = false;

  Future<void> _export(
    BuildContext context,
    String format,
    List<Facility> facilities,
    List<Inspection> inspections,
    Map<String, User> userMap,
  ) async {
    setState(() => _exporting = true);
    try {
      final facilityIds = {for (final f in facilities) f.id};
      final myInspections =
          inspections.where((i) => facilityIds.contains(i.facilityId)).toList();

      final facilityMap = {for (final f in facilities) f.id: f};
      final rows = myInspections
          .map((i) =>
              InspectionReportRow.fromInspection(i, facilityMap, userMap))
          .toList();

      final mandalLabel = widget.mandalId.isEmpty
          ? 'Mandal'
          : '${widget.mandalId[0].toUpperCase()}${widget.mandalId.substring(1)}';
      final title = 'FIMMS Mandal Report — $mandalLabel';
      final subtitle =
          '${rows.length} inspections  ·  ${facilities.length} facilities';
      final filename =
          'fimms_mandal_${widget.mandalId}_${DateTime.now().millisecondsSinceEpoch}';

      if (format == 'csv') {
        final csv = buildInspectionCsv(rows, title);
        await downloadCsv(csv, '$filename.csv');
      } else {
        final pdf =
            await buildInspectionPdf(rows, title, subtitle);
        await downloadPdf(pdf, '$filename.pdf');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showExportSheet(
    BuildContext context,
    List<Facility> facilities,
    List<Inspection> inspections,
    Map<String, User> userMap,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Download Report',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Choose a format to export the inspection data.',
                  style: TextStyle(
                      fontSize: 12, color: FimmsColors.textMuted)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _FormatButton(
                      icon: Icons.table_chart_outlined,
                      label: 'CSV',
                      sublabel: 'Spreadsheet',
                      color: FimmsColors.success,
                      onTap: () {
                        Navigator.pop(context);
                        _export(context, 'csv', facilities,
                            inspections, userMap);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormatButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      sublabel: 'Document',
                      color: FimmsColors.danger,
                      onTap: () {
                        Navigator.pop(context);
                        _export(context, 'pdf', facilities,
                            inspections, userMap);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final usersAsync = ref.watch(usersProvider);

    return Column(
      children: [
        // Export bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: FimmsColors.surface,
          child: Row(
            children: [
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _exporting
                    ? null
                    : () {
                        final facilities =
                            facilitiesAsync.valueOrNull ?? <Facility>[];
                        final inspections =
                            inspectionsAsync.valueOrNull ?? <Inspection>[];
                        final userMap = {
                          for (final u in usersAsync.valueOrNull ?? <User>[])
                            u.id: u
                        };
                        _showExportSheet(
                            context, facilities, inspections, userMap);
                      },
                icon: _exporting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined, size: 14),
                label: Text(_exporting ? 'Exporting…' : 'Export'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11),
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
              // moduleFacilitiesProvider already filters by active module.
              final filtered = facilities
                  .where((f) => f.mandalId == widget.mandalId)
                  .toList();

              return inspectionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    _buildContent(context, filtered, []),
                data: (inspections) =>
                    _buildContent(context, filtered, inspections),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<Facility> facilities,
      List<Inspection> inspections) {
    final facilityIds = {for (final f in facilities) f.id};
    final myInspections =
        inspections.where((i) => facilityIds.contains(i.facilityId)).toList();

    // Summary cards
    final totalFacilities = facilities.length;
    final inspectedCount = myInspections
        .map((i) => i.facilityId)
        .toSet()
        .length;
    final criticalCount =
        myInspections.where((i) => i.urgentFlag).length;
    final avgScore = myInspections.isEmpty
        ? 0.0
        : myInspections.map((i) => i.totalScore).reduce((a, b) => a + b) /
            myInspections.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary row
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Facilities',
                value: '$totalFacilities',
                icon: Icons.business_outlined,
                color: FimmsColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Inspected',
                value: '$inspectedCount',
                icon: Icons.fact_check_outlined,
                color: FimmsColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Avg Score',
                value: avgScore.toStringAsFixed(0),
                icon: Icons.bar_chart,
                color: FimmsColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Urgent',
                value: '$criticalCount',
                icon: Icons.warning_amber_outlined,
                color: FimmsColors.danger,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Monthly table header
        const Text(
          'Monthly Summary',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: FimmsColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FimmsColors.outline),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: FimmsColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Month',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))),
                    Expanded(
                        flex: 2,
                        child: Text('Completion',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))),
                    Expanded(
                        flex: 2,
                        child: Text('Issues',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))),
                    Expanded(
                        flex: 2,
                        child: Text('Complaints',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))),
                  ],
                ),
              ),
              // Rows
              for (int i = 0; i < _mockMonthly.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 12, endIndent: 12),
                _MonthRowWidget(row: _mockMonthly[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthRowWidget extends StatelessWidget {
  final _MonthRow row;
  const _MonthRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    final pct = row.completionPct;
    final pctColor = pct >= 90
        ? FimmsColors.success
        : pct >= 70
            ? FimmsColors.warning
            : FimmsColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(row.month,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: pctColor),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: FimmsColors.outline,
                  color: pctColor,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                Text('${row.completed}/${row.total}',
                    style: const TextStyle(
                        fontSize: 10, color: FimmsColors.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.issueCount}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.complaintCount}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _FormatButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(sublabel,
                style: const TextStyle(
                    fontSize: 11, color: FimmsColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FimmsColors.textMuted)),
        ],
      ),
    );
  }
}
