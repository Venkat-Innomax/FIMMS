import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';

/// Dashboard filter state (facility type + grade set).
class DashboardFilter {
  final FacilityType? type; // null = all
  final Set<Grade> grades;  // empty = all
  final bool urgentOnly;

  const DashboardFilter({
    this.type,
    this.grades = const {},
    this.urgentOnly = false,
  });

  DashboardFilter copyWith({
    FacilityType? type,
    bool clearType = false,
    Set<Grade>? grades,
    bool? urgentOnly,
  }) {
    return DashboardFilter(
      type: clearType ? null : (type ?? this.type),
      grades: grades ?? this.grades,
      urgentOnly: urgentOnly ?? this.urgentOnly,
    );
  }
}

class DashboardFilterNotifier extends StateNotifier<DashboardFilter> {
  DashboardFilterNotifier() : super(const DashboardFilter());

  void setType(FacilityType? t) {
    state = state.copyWith(type: t, clearType: t == null);
  }

  void toggleGrade(Grade g) {
    final next = {...state.grades};
    if (!next.add(g)) next.remove(g);
    state = state.copyWith(grades: next);
  }

  void setUrgentOnly(bool v) => state = state.copyWith(urgentOnly: v);

  void reset() => state = const DashboardFilter();
}

final dashboardFilterProvider =
    StateNotifierProvider<DashboardFilterNotifier, DashboardFilter>(
  (ref) => DashboardFilterNotifier(),
);

class FilterPanel extends ConsumerWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dashboardFilterProvider);
    final notifier = ref.read(dashboardFilterProvider.notifier);

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
          Row(
            children: [
              const Icon(Icons.tune, size: 16, color: FimmsColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'FILTERS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.textMuted,
                      letterSpacing: 0.8,
                    ),
              ),
              const Spacer(),
              if (filter.type != null ||
                  filter.grades.isNotEmpty ||
                  filter.urgentOnly)
                TextButton(
                  onPressed: notifier.reset,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const _Label('Facility Type'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              _Radio(
                label: 'All',
                selected: filter.type == null,
                onTap: () => notifier.setType(null),
              ),
              _Radio(
                label: 'Hostels',
                selected: filter.type == FacilityType.hostel,
                onTap: () => notifier.setType(FacilityType.hostel),
              ),
              _Radio(
                label: 'Hospitals',
                selected: filter.type == FacilityType.hospital,
                onTap: () => notifier.setType(FacilityType.hospital),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _Label('Grade'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final g in Grade.values)
                _GradeChip(
                  grade: g,
                  selected: filter.grades.contains(g),
                  onTap: () => notifier.toggleGrade(g),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Switch(
                value: filter.urgentOnly,
                onChanged: notifier.setUrgentOnly,
                activeThumbColor: FimmsColors.secondary,
              ),
              const SizedBox(width: 8),
              const Text('Urgent flags only',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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

class _Radio extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Radio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? FimmsColors.primary
              : FimmsColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? FimmsColors.primary : FimmsColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : FimmsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final Grade grade;
  final bool selected;
  final VoidCallback onTap;
  const _GradeChip({
    required this.grade,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = grade.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : FimmsColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : FimmsColors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              grade.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : FimmsColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
