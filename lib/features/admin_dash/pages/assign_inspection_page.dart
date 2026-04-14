import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/assignment.dart';
import '../../../models/facility.dart';
import '../../../models/user.dart';

class AssignInspectionPage extends ConsumerStatefulWidget {
  const AssignInspectionPage({super.key});

  @override
  ConsumerState<AssignInspectionPage> createState() =>
      _AssignInspectionPageState();
}

class _AssignInspectionPageState extends ConsumerState<AssignInspectionPage> {
  Facility? _selectedFacility;
  User? _selectedOfficer;
  late DateTime _dueDate;
  bool _isReinspection = false;
  String _facilitySearch = '';
  String _officerSearch = '';

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 1));
  }

  void _resetForm() {
    setState(() {
      _selectedFacility = null;
      _selectedOfficer = null;
      _dueDate = DateTime.now().add(const Duration(days: 1));
      _isReinspection = false;
      _facilitySearch = '';
      _officerSearch = '';
    });
  }

  void _submit() {
    if (_selectedFacility == null || _selectedOfficer == null) return;

    final assignment = Assignment(
      id: 'asgn_${DateTime.now().millisecondsSinceEpoch}',
      facilityId: _selectedFacility!.id,
      officerId: _selectedOfficer!.id,
      assignedBy: 'admin_01',
      dueDate: _dueDate,
      status: AssignmentStatus.pending,
      isReinspection: _isReinspection,
    );

    ref.read(assignmentListProvider.notifier).add(assignment);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Assigned ${_selectedFacility!.name} to ${_selectedOfficer!.name}',
        ),
        backgroundColor: FimmsColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _resetForm();
  }

  /// Find the nearest field officer to the selected facility based on
  /// mandal match first, then geo-distance as tiebreaker.
  void _selectNearestOfficer(
      List<User> fieldOfficers, List<Facility> facilities) {
    if (_selectedFacility == null || fieldOfficers.isEmpty) return;

    final facilityMandal = _selectedFacility!.mandalId;
    final facilityLat = _selectedFacility!.location.latitude;
    final facilityLng = _selectedFacility!.location.longitude;

    // Build a map of officer -> their facilities (to get location)
    final officerFacilities = <String, Facility>{};
    for (final officer in fieldOfficers) {
      if (officer.facilityId != null) {
        final f = facilities.where((f) => f.id == officer.facilityId);
        if (f.isNotEmpty) officerFacilities[officer.id] = f.first;
      }
    }

    // Priority 1: Officers in the same mandal
    final sameMandalOfficers =
        fieldOfficers.where((u) => u.mandalId == facilityMandal).toList();

    // Priority 2: Officers with fewest pending assignments (least loaded)
    final assignments = ref.read(assignmentListProvider);
    final pendingCount = <String, int>{};
    for (final a in assignments) {
      if (a.status == AssignmentStatus.pending ||
          a.status == AssignmentStatus.inProgress) {
        pendingCount[a.officerId] = (pendingCount[a.officerId] ?? 0) + 1;
      }
    }

    // Scoring: same mandal officers first, then sort by distance + workload
    double score(User u) {
      double s = 0;
      // Same mandal bonus
      if (u.mandalId == facilityMandal) s -= 10000;
      // Workload penalty
      s += (pendingCount[u.id] ?? 0) * 100;
      // Geo distance (if officer has a facility with location)
      final of = officerFacilities[u.id];
      if (of != null) {
        final dLat = facilityLat - of.location.latitude;
        final dLng = facilityLng - of.location.longitude;
        s += sqrt(dLat * dLat + dLng * dLng) * 1000;
      }
      return s;
    }

    final candidates =
        sameMandalOfficers.isNotEmpty ? sameMandalOfficers : fieldOfficers;
    final sorted = [...candidates]..sort((a, b) => score(a).compareTo(score(b)));

    setState(() => _selectedOfficer = sorted.first);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Auto-selected nearest officer: ${sorted.first.name}'
          '${sorted.first.mandalId != null ? ' (${sorted.first.mandalId})' : ''}'
          ' — ${pendingCount[sorted.first.id] ?? 0} pending tasks',
        ),
        backgroundColor: FimmsColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final usersAsync = ref.watch(usersProvider);
    final assignments = ref.watch(assignmentListProvider);

    final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
    final users = usersAsync.valueOrNull ?? <User>[];
    final fieldOfficers =
        users.where((u) => u.role == Role.fieldOfficer).toList();

    final facilityMap = {for (final f in facilities) f.id: f};
    final userMap = {for (final u in users) u.id: u};

    final isWide = MediaQuery.sizeOf(context).width >= 800;

    // Sidebar form
    final formPanel = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.assignment_add,
                    size: 18, color: FimmsColors.primary),
                const SizedBox(width: 8),
                Text(
                  'ASSIGN INSPECTION',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: FimmsColors.primary,
                        letterSpacing: 0.8,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Facility dropdown
            const _FieldLabel('Facility'),
            const SizedBox(height: 6),
            _SearchableDropdown<Facility>(
              hint: 'Select facility',
              value: _selectedFacility,
              items: facilities,
              searchQuery: _facilitySearch,
              onSearchChanged: (q) => setState(() => _facilitySearch = q),
              filter: (f, q) =>
                  f.name.toLowerCase().contains(q.toLowerCase()),
              itemBuilder: (f) => Row(
                children: [
                  Expanded(
                    child: Text(f.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: f.type == FacilityType.hostel
                          ? FimmsColors.primary.withValues(alpha: 0.1)
                          : FimmsColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      f.type.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: f.type == FacilityType.hostel
                            ? FimmsColors.primary
                            : FimmsColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              selectedLabel: (f) => f.name,
              onSelected: (f) => setState(() {
                _selectedFacility = f;
                _selectedOfficer = null;
              }),
            ),
            const SizedBox(height: 14),

            // Officer dropdown + Nearest button
            const _FieldLabel('Field Officer'),
            const SizedBox(height: 6),
            _SearchableDropdown<User>(
              hint: 'Select officer',
              value: _selectedOfficer,
              items: fieldOfficers,
              searchQuery: _officerSearch,
              onSearchChanged: (q) => setState(() => _officerSearch = q),
              filter: (u, q) =>
                  u.name.toLowerCase().contains(q.toLowerCase()),
              itemBuilder: (u) => Row(
                children: [
                  Expanded(
                    child: Text(u.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (u.mandalId != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      u.mandalId!,
                      style: const TextStyle(
                          fontSize: 10, color: FimmsColors.textMuted),
                    ),
                  ],
                ],
              ),
              selectedLabel: (u) => u.name,
              onSelected: (u) => setState(() => _selectedOfficer = u),
            ),
            const SizedBox(height: 8),

            // Select Nearest Officer button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectedFacility != null
                    ? () => _selectNearestOfficer(fieldOfficers, facilities)
                    : null,
                icon: const Icon(Icons.near_me, size: 15),
                label: const Text('Select Nearest Officer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FimmsColors.primary,
                  side: BorderSide(
                    color: _selectedFacility != null
                        ? FimmsColors.primary
                        : FimmsColors.outline,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (_selectedFacility != null && _selectedOfficer == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tip: Pick a facility first, then auto-select the nearest available officer',
                  style: TextStyle(
                    fontSize: 10,
                    color: FimmsColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // Due date
            const _FieldLabel('Due Date'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: FimmsColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FimmsColors.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: FimmsColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(_dueDate),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Re-inspection toggle
            Row(
              children: [
                SizedBox(
                  height: 28,
                  child: Switch(
                    value: _isReinspection,
                    onChanged: (v) => setState(() => _isReinspection = v),
                    activeThumbColor: FimmsColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Re-inspection',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),

            // Assign button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _selectedFacility != null && _selectedOfficer != null
                        ? _submit
                        : null,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Assign'),
              ),
            ),
          ],
        ),
      ),
    );

    // Assignment list (right side on desktop, below on mobile)
    final listPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Row(
            children: [
              Text(
                '${assignments.length} assignments',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textPrimary),
              ),
              const Spacer(),
              Text(
                'Pending: ${assignments.where((a) => a.status == AssignmentStatus.pending).length}',
                style: const TextStyle(
                    fontSize: 12, color: FimmsColors.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: assignments.isEmpty
              ? const Center(
                  child: Text('No assignments yet',
                      style: TextStyle(color: FimmsColors.textMuted)),
                )
              : ListView.separated(
                  itemCount: assignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    // Show newest first
                    final a = assignments[assignments.length - 1 - index];
                    final facility = facilityMap[a.facilityId];
                    final officer = userMap[a.officerId];
                    return _AssignmentCard(
                      assignment: a,
                      facilityName: facility?.name ?? a.facilityId,
                      officerName: officer?.name ?? a.officerId,
                    );
                  },
                ),
        ),
      ],
    );

    if (isWide) {
      // Desktop: sidebar form on left, assignment list on right
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: formPanel,
            ),
            const SizedBox(width: 20),
            Expanded(child: listPanel),
          ],
        ),
      );
    }

    // Mobile: form on top, list below
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: formPanel,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: listPanel,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: FimmsColors.textMuted,
      ),
    );
  }
}

class _SearchableDropdown<T> extends StatefulWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool Function(T item, String query) filter;
  final Widget Function(T item) itemBuilder;
  final String Function(T item) selectedLabel;
  final ValueChanged<T> onSelected;

  const _SearchableDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.filter,
    required this.itemBuilder,
    required this.selectedLabel,
    required this.onSelected,
  });

  @override
  State<_SearchableDropdown<T>> createState() =>
      _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<_SearchableDropdown<T>> {
  bool _expanded = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return InkWell(
        onTap: () => setState(() {
          _expanded = true;
          _controller.clear();
          widget.onSearchChanged('');
        }),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: FimmsColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FimmsColors.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.value != null
                      ? widget.selectedLabel(widget.value as T)
                      : widget.hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.value != null
                        ? FimmsColors.textPrimary
                        : FimmsColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down,
                  size: 18, color: FimmsColors.textMuted),
            ],
          ),
        ),
      );
    }

    final filtered = widget.searchQuery.isEmpty
        ? widget.items
        : widget.items
            .where((i) => widget.filter(i, widget.searchQuery))
            .toList();

    return Container(
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FimmsColors.primary, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(fontSize: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return InkWell(
                  onTap: () {
                    widget.onSelected(item);
                    setState(() => _expanded = false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: widget.itemBuilder(item),
                  ),
                );
              },
            ),
          ),
          InkWell(
            onTap: () => setState(() => _expanded = false),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Text('Close',
                    style: TextStyle(
                        fontSize: 11,
                        color: FimmsColors.textMuted,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final String facilityName;
  final String officerName;

  const _AssignmentCard({
    required this.assignment,
    required this.facilityName,
    required this.officerName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: FimmsColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (assignment.isReinspection)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: FimmsColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('RE-INSPECT',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: FimmsColors.secondary)),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(facilityName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Officer: $officerName',
                      style: const TextStyle(
                          fontSize: 12, color: FimmsColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusChip(status: assignment.status),
                const SizedBox(height: 4),
                Text(
                  'Due: ${DateFormat('dd MMM').format(assignment.dueDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: assignment.dueDate.isBefore(DateTime.now())
                        ? FimmsColors.danger
                        : FimmsColors.textMuted,
                    fontWeight: assignment.dueDate.isBefore(DateTime.now())
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AssignmentStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      AssignmentStatus.pending => (Colors.blue, Icons.schedule),
      AssignmentStatus.inProgress => (Colors.orange, Icons.play_arrow),
      AssignmentStatus.completed =>
        (FimmsColors.success, Icons.check_circle),
      AssignmentStatus.overdue => (FimmsColors.danger, Icons.warning),
      AssignmentStatus.cancelled => (Colors.grey, Icons.cancel),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
