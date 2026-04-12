import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../models/facility.dart';

class FacilityMasterPage extends ConsumerStatefulWidget {
  const FacilityMasterPage({super.key});

  @override
  ConsumerState<FacilityMasterPage> createState() => _FacilityMasterPageState();
}

class _FacilityMasterPageState extends ConsumerState<FacilityMasterPage> {
  String _search = '';
  FacilityType? _typeFilter;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return facilitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (facilities) {
        var filtered = facilities.where((f) {
          if (_typeFilter != null && f.type != _typeFilter) return false;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            return f.name.toLowerCase().contains(q) ||
                f.village.toLowerCase().contains(q) ||
                f.mandalId.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        filtered.sort((a, b) {
          int cmp;
          switch (_sortColumnIndex) {
            case 0:
              cmp = a.name.compareTo(b.name);
            case 1:
              cmp = a.type.name.compareTo(b.type.name);
            case 2:
              cmp = a.mandalId.compareTo(b.mandalId);
            case 3:
              cmp = a.village.compareTo(b.village);
            default:
              cmp = 0;
          }
          return _sortAscending ? cmp : -cmp;
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 12),
                  SegmentedButton<FacilityType?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(
                          value: FacilityType.hostel, label: Text('Hostel')),
                      ButtonSegment(
                          value: FacilityType.hospital, label: Text('Hospital')),
                    ],
                    selected: {_typeFilter},
                    onSelectionChanged: (s) =>
                        setState(() => _typeFilter = s.first),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add facility (demo mode)')),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${filtered.length} facilities',
                style: TextStyle(
                    color: FimmsColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    headingRowColor:
                        WidgetStateProperty.all(FimmsColors.surface),
                    columns: [
                      DataColumn(
                        label: const Text('Name'),
                        onSort: (i, asc) => setState(() {
                          _sortColumnIndex = i;
                          _sortAscending = asc;
                        }),
                      ),
                      DataColumn(
                        label: const Text('Type'),
                        onSort: (i, asc) => setState(() {
                          _sortColumnIndex = i;
                          _sortAscending = asc;
                        }),
                      ),
                      DataColumn(
                        label: const Text('Mandal'),
                        onSort: (i, asc) => setState(() {
                          _sortColumnIndex = i;
                          _sortAscending = asc;
                        }),
                      ),
                      DataColumn(
                        label: const Text('Village'),
                        onSort: (i, asc) => setState(() {
                          _sortColumnIndex = i;
                          _sortAscending = asc;
                        }),
                      ),
                      const DataColumn(label: Text('Sub-Type')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered.map((f) {
                      return DataRow(cells: [
                        DataCell(Text(f.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(_TypeChip(type: f.type)),
                        DataCell(Text(f.mandalId)),
                        DataCell(Text(f.village)),
                        DataCell(Text(f.subType)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Edit facility (demo mode)')),
                              ),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  final FacilityType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final isHostel = type == FacilityType.hostel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isHostel ? Colors.purple : Colors.teal).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isHostel ? 'Hostel' : 'Hospital',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isHostel ? Colors.purple : Colors.teal,
        ),
      ),
    );
  }
}
