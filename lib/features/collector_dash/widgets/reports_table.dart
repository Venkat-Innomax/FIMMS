import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

