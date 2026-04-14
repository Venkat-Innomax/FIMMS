import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../models/facility.dart';

class FacilityPicker extends ConsumerStatefulWidget {
  final ValueChanged<Facility> onSelected;
  final String? selectedId;

  const FacilityPicker({
    super.key,
    required this.onSelected,
    this.selectedId,
  });

  @override
  ConsumerState<FacilityPicker> createState() => _FacilityPickerState();
}

class _FacilityPickerState extends ConsumerState<FacilityPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);

    return facilitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (facilities) {
        var filtered = facilities;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          filtered = filtered
              .where((f) =>
                  f.name.toLowerCase().contains(q) ||
                  f.mandalId.toLowerCase().contains(q) ||
                  f.village.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search facility by name, mandal, village...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final f = filtered[index];
                  final isSelected = f.id == widget.selectedId;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor:
                        FimmsColors.primary.withValues(alpha: 0.06),
                    leading: Icon(
                      f.type == FacilityType.hostel
                          ? Icons.hotel
                          : Icons.local_hospital,
                      size: 18,
                      color: f.type == FacilityType.hostel
                          ? Colors.purple
                          : Colors.teal,
                    ),
                    title: Text(f.name,
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${f.mandalId} · ${f.type == FacilityType.hostel ? "Hostel" : "Hospital"}',
                      style: const TextStyle(fontSize: 10.5),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            size: 18, color: FimmsColors.primary)
                        : null,
                    onTap: () => widget.onSelected(f),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
