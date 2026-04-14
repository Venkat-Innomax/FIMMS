import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/export_utils.dart';
import '../../../core/theme.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../../models/user.dart';
import '../../shared_widgets/empty_state.dart';
import '../../shared_widgets/grade_chip.dart';

class ReportsTable extends StatefulWidget {
  final List<Inspection> inspections;
  final Map<String, Facility> facilityMap;
  final Map<String, User> userMap;

  const ReportsTable({
    super.key,
    required this.inspections,
    required this.facilityMap,
    required this.userMap,
  });

  @override
  State<ReportsTable> createState() => _ReportsTableState();
}

class _ReportsTableState extends State<ReportsTable> {
  String _search = '';
  int _sortColumnIndex = 4; // date
  bool _sortAscending = false; // newest first
  bool _exporting = false;

  Future<void> _export(BuildContext context, String format) async {
    setState(() => _exporting = true);
    try {
      final rows = widget.inspections
          .map((i) => InspectionReportRow.fromInspection(
              i, widget.facilityMap, widget.userMap))
          .toList();
      const title = 'FIMMS Collector District Report';
      const subtitle = 'District-wide inspection data';
      final filename =
          'fimms_district_${DateTime.now().millisecondsSinceEpoch}';

      if (format == 'csv') {
        final csv = buildInspectionCsv(rows, title);
        await downloadCsv(csv, '$filename.csv');
      } else {
        final pdf = await buildInspectionPdf(rows, title, subtitle);
        await downloadPdf(pdf, '$filename.pdf');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showExportSheet(BuildContext context) {
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
              const Text(
                  'Export the current inspection table as CSV or PDF.',
                  style: TextStyle(
                      fontSize: 12, color: FimmsColors.textMuted)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ExportFormatTile(
                      icon: Icons.table_chart_outlined,
                      label: 'CSV',
                      sublabel: 'Spreadsheet',
                      color: FimmsColors.success,
                      onTap: () {
                        Navigator.pop(context);
                        _export(context, 'csv');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ExportFormatTile(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      sublabel: 'Document',
                      color: FimmsColors.danger,
                      onTap: () {
                        Navigator.pop(context);
                        _export(context, 'pdf');
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
    var filtered = widget.inspections;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((i) {
        final f = widget.facilityMap[i.facilityId];
        return (f?.name.toLowerCase().contains(q) ?? false) ||
            (f?.mandalId.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    filtered = List.of(filtered);
    filtered.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 4:
          cmp = a.datetime.compareTo(b.datetime);
        case 5:
          cmp = a.totalScore.compareTo(b.totalScore);
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by facility or mandal...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    _exporting ? null : () => _showExportSheet(context),
                icon: _exporting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined, size: 14),
                label: Text(_exporting ? 'Exporting…' : 'Export'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.table_chart_outlined,
                  title: 'No inspection reports found',
                  subtitle: 'Try adjusting your search criteria.',
                )
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                headingRowColor:
                    WidgetStateProperty.all(FimmsColors.surface),
                columns: [
                  const DataColumn(label: Text('Facility')),
                  const DataColumn(label: Text('Type')),
                  const DataColumn(label: Text('Mandal')),
                  const DataColumn(label: Text('Officer')),
                  DataColumn(
                    label: const Text('Date'),
                    onSort: (i, asc) => setState(() {
                      _sortColumnIndex = i;
                      _sortAscending = asc;
                    }),
                  ),
                  DataColumn(
                    label: const Text('Score'),
                    numeric: true,
                    onSort: (i, asc) => setState(() {
                      _sortColumnIndex = i;
                      _sortAscending = asc;
                    }),
                  ),
                  const DataColumn(label: Text('Grade')),
                  const DataColumn(label: Text('Status')),
                ],
                rows: filtered.map((i) {
                  final f = widget.facilityMap[i.facilityId];
                  final u = widget.userMap[i.officerId];
                  return DataRow(cells: [
                    DataCell(Text(f?.name ?? i.facilityId,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(f?.type.name ?? '')),
                    DataCell(Text(f?.mandalId ?? '')),
                    DataCell(Text(u?.name ?? i.officerId)),
                    DataCell(Text(
                        DateFormat('dd MMM yyyy').format(i.datetime))),
                    DataCell(Text('${i.totalScore.round()}')),
                    DataCell(GradeChip(grade: i.grade, compact: true)),
                    DataCell(Text(i.status.label,
                        style: const TextStyle(fontSize: 12))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportFormatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _ExportFormatTile({
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

