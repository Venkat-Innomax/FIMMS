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

class AssignPanel extends ConsumerStatefulWidget {
  const AssignPanel({super.key});

  @override
  ConsumerState<AssignPanel> createState() => _AssignPanelState();
}

class _AssignPanelState extends ConsumerState<AssignPanel> {
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
      assignedBy: 'collector_01',
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

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);
    final usersAsync = ref.watch(usersProvider);
    final assignments = ref.watch(assignmentListProvider);

    final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
    final users = usersAsync.valueOrNull ?? <User>[];
    final fieldOfficers =
        users.where((u) => u.role == Role.fieldOfficer).toList();

    final facilityMap = {for (final f in facilities) f.id: f};
    final userMap = {for (final u in users) u.id: u};

    // Recent pending/in-progress assignments (last 5)
    final recent = assignments
        .where((a) =>
            a.status == AssignmentStatus.pending ||
            a.status == AssignmentStatus.inProgress)
        .toList()
        .reversed
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.assignment_add, size: 16, color: FimmsColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'ASSIGN INSPECTION',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.textMuted,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Facility dropdown
          const _FieldLabel('Facility'),
          const SizedBox(height: 4),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
            onSelected: (f) => setState(() => _selectedFacility = f),
          ),
          const SizedBox(height: 10),

          // Officer dropdown
          const _FieldLabel('Field Officer'),
          const SizedBox(height: 4),
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
          const SizedBox(height: 10),

          // Due date
          const _FieldLabel('Due Date'),
          const SizedBox(height: 4),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          const SizedBox(height: 10),

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
          const SizedBox(height: 12),

          // Assign button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedFacility != null && _selectedOfficer != null
                  ? _submit
                  : null,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Assign'),
            ),
          ),

          // Recent assignments
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'RECENT (${recent.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textMuted,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 8),
            for (final a in recent)
              _RecentAssignmentTile(
                assignment: a,
                facilityName: facilityMap[a.facilityId]?.name ?? a.facilityId,
                officerName: userMap[a.officerId]?.name ?? a.officerId,
              ),
          ],
        ],
      ),
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
  State<_SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            constraints: const BoxConstraints(maxHeight: 150),
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
          // Close button
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

class _RecentAssignmentTile extends StatelessWidget {
  final Assignment assignment;
  final String facilityName;
  final String officerName;

  const _RecentAssignmentTile({
    required this.assignment,
    required this.facilityName,
    required this.officerName,
  });

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (assignment.status) {
      AssignmentStatus.pending => (Colors.blue, Icons.schedule),
      AssignmentStatus.inProgress => (Colors.orange, Icons.play_arrow),
      AssignmentStatus.completed => (FimmsColors.success, Icons.check_circle),
      AssignmentStatus.overdue => (FimmsColors.danger, Icons.warning),
      AssignmentStatus.cancelled => (Colors.grey, Icons.cancel),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: FimmsColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$facilityName → $officerName',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Due ${DateFormat('dd MMM').format(assignment.dueDate)}',
                      style: const TextStyle(
                          fontSize: 10.5, color: FimmsColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 10, color: color),
                          const SizedBox(width: 3),
                          Text(
                            assignment.status.label,
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
