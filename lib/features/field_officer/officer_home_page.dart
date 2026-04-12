import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/repositories/facility_repository.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../models/facility.dart';
import '../../models/inspection.dart';
import '../../models/user.dart';
import '../../services/mock_auth_service.dart';
import '../shared_widgets/grade_chip.dart';
import '../shared_widgets/responsive_scaffold.dart';

/// Three-tab shell for the Field Officer app: Assignments, History, Profile.
class OfficerHomePage extends ConsumerStatefulWidget {
  const OfficerHomePage({super.key});

  @override
  ConsumerState<OfficerHomePage> createState() => _OfficerHomePageState();
}

class _OfficerHomePageState extends ConsumerState<OfficerHomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

    return ResponsiveScaffold(
      title: 'FIMMS — Field Officer',
      items: const [
        NavItem(
            label: 'Assignments',
            icon: Icons.assignment_outlined,
            route: '/officer'),
        NavItem(
            label: 'History', icon: Icons.history, route: '/officer/history'),
        NavItem(
            label: 'Profile',
            icon: Icons.person_outline,
            route: '/officer/profile'),
      ],
      currentIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      body: IndexedStack(
        index: _tab,
        children: [
          _AssignmentsTab(officer: user),
          _HistoryTab(officer: user),
          _ProfileTab(officer: user),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends ConsumerWidget {
  final User? officer;
  const _AssignmentsTab({required this.officer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilities = ref.watch(facilitiesProvider);
    final inspections = ref.watch(inspectionsProvider);

    return facilities.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed: $e')),
      data: (allFacilities) {
        final mandal = officer?.mandalId;
        // Assignments: facilities in officer's mandal that haven't been
        // inspected today. (Demo heuristic.)
        final candidates =
            allFacilities.where((f) => f.mandalId == mandal).toList();
        return inspections.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed: $e')),
          data: (allInspections) {
            final byFacility = <String, Inspection>{};
            for (final i in allInspections) {
              byFacility[i.facilityId] = i;
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: candidates.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Row(
                      children: [
                        Text(
                          'TODAY — ${DateFormat('EEE, d MMM').format(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: FimmsColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${candidates.length} assigned',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: FimmsColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final f = candidates[idx - 1];
                final last = byFacility[f.id];
                return _AssignmentCard(facility: f, last: last);
              },
            );
          },
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Facility facility;
  final Inspection? last;

  const _AssignmentCard({required this.facility, required this.last});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FimmsColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: FimmsColors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/officer/inspect/${facility.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: FimmsColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      facility.type == FacilityType.hostel
                          ? Icons.house_outlined
                          : Icons.local_hospital_outlined,
                      color: FimmsColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${facility.subTypeLabel} · ${facility.village}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: FimmsColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: FimmsColors.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (last != null) ...[
                    GradeChip(
                      grade: last!.grade,
                      scoreOutOf100: last!.totalScore,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last ${DateFormat('d MMM').format(last!.datetime)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: FimmsColors.textMuted,
                      ),
                    ),
                  ] else
                    Text(
                      'No prior inspection',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: FimmsColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () =>
                        context.go('/officer/inspect/${facility.id}'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Start Inspection'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  final User? officer;
  const _HistoryTab({required this.officer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspections = ref.watch(inspectionsProvider);
    final facilities = ref.watch(facilitiesProvider);

    return inspections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed: $e')),
      data: (all) => facilities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (allF) {
          final fById = {for (final f in allF) f.id: f};
          final mine = all.where((i) => i.officerId == officer?.id).toList()
            ..sort((a, b) => b.datetime.compareTo(a.datetime));
          if (mine.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No submitted inspections yet.',
                  style: TextStyle(color: FimmsColors.textMuted),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: mine.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final i = mine[idx];
              final f = fById[i.facilityId];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FimmsColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FimmsColors.outline),
                ),
                child: Row(
                  children: [
                    GradeChip(
                      grade: i.grade,
                      scoreOutOf100: i.totalScore,
                      compact: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f?.name ?? i.facilityId,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('d MMM yyyy · h:mm a')
                                .format(i.datetime),
                            style: const TextStyle(
                              fontSize: 11,
                              color: FimmsColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i.urgentFlag) const UrgentBadge(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  final User? officer;
  const _ProfileTab({required this.officer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = officer;
    // Extension-resolved properties (RoleX.label) require a statically
    // typed receiver — resolve them into plain Strings up here rather
    // than chaining `?.role?.label` inline on a nullable value.
    final roleLabel = o?.role.label ?? '—';
    String mandalLabel = '—';
    if (o != null) {
      final m = o.mandalId;
      if (m != null && m.isNotEmpty) {
        mandalLabel = '${m[0].toUpperCase()}${m.substring(1)}';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FimmsBrandMark(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FimmsColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FimmsColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o?.name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o?.designation ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: FimmsColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _KeyValue(label: 'Role', value: roleLabel),
                    _KeyValue(label: 'Mandal', value: mandalLabel),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(authStateProvider.notifier).signOut();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: FimmsColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
