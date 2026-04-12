import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../data/repositories/facility_repository.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../models/facility.dart';
import '../../models/inspection.dart';
import '../../models/mandal.dart';
import '../../models/user.dart';
import '../shared_widgets/responsive_scaffold.dart';
import 'widgets/alerts_panel.dart';
import 'widgets/district_map.dart';
import 'widgets/facility_popup.dart';
import 'widgets/filter_panel.dart';
import 'widgets/mandal_bars.dart';
import 'widgets/reports_table.dart';
import 'widgets/stat_card_row.dart';
import 'widgets/trend_chart.dart';

class CollectorDashboardPage extends ConsumerStatefulWidget {
  final String? mandalScopeId;
  final bool showMandalFilter;

  const CollectorDashboardPage({
    super.key,
    this.mandalScopeId,
    this.showMandalFilter = true,
  });

  @override
  ConsumerState<CollectorDashboardPage> createState() =>
      _CollectorDashboardPageState();
}

enum _ViewMode { map, reports, trends }

class _CollectorDashboardPageState
    extends ConsumerState<CollectorDashboardPage> {
  Facility? _selected;
  _ViewMode _viewMode = _ViewMode.map;

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final mandalsAsync = ref.watch(mandalsProvider);
    final usersAsync = ref.watch(usersProvider);
    final filter = ref.watch(dashboardFilterProvider);

    // Collect errors so we can surface them on the screen instead of
    // showing a silent infinite spinner when a fixture fails to parse.
    final errors = <String>[];
    if (facilitiesAsync.hasError) {
      errors.add('facilities: ${facilitiesAsync.error}');
    }
    if (inspectionsAsync.hasError) {
      errors.add('inspections: ${inspectionsAsync.error}');
    }
    if (mandalsAsync.hasError) {
      errors.add('mandals: ${mandalsAsync.error}');
    }
    if (usersAsync.hasError) {
      errors.add('users: ${usersAsync.error}');
    }

    final allLoaded = facilitiesAsync.hasValue &&
        inspectionsAsync.hasValue &&
        mandalsAsync.hasValue &&
        usersAsync.hasValue;

    Widget body;
    if (errors.isNotEmpty) {
      body = _DataErrorPanel(errors: errors);
    } else if (!allLoaded) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = _buildContent(
        facilities: facilitiesAsync.value!,
        inspections: inspectionsAsync.value!,
        mandals: mandalsAsync.value!,
        users: usersAsync.value!,
        filter: filter,
      );
    }

    return DashboardScaffold(
      title: widget.mandalScopeId == null
          ? 'Collector Dashboard'
          : 'Mandal Dashboard',
      subtitle: widget.mandalScopeId == null
          ? '${AppConstants.districtName}, ${AppConstants.stateName}'
          : 'Mandal: ${_cap(widget.mandalScopeId!)}',
      body: body,
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildContent({
    required List<Facility> facilities,
    required List<Inspection> inspections,
    required List<Mandal> mandals,
    required List<User> users,
    required DashboardFilter filter,
  }) {
    // Scope to mandal (if mandal dashboard).
    if (widget.mandalScopeId != null) {
      facilities =
          facilities.where((f) => f.mandalId == widget.mandalScopeId).toList();
    }

    // Build inspection index by facility id (keep the latest for each).
    final insByFacility = <String, Inspection>{};
    for (final i in inspections) {
      final existing = insByFacility[i.facilityId];
      if (existing == null || i.datetime.isAfter(existing.datetime)) {
        insByFacility[i.facilityId] = i;
      }
    }

    // Apply filter.
    bool matches(Facility f) {
      if (filter.type != null && f.type != filter.type) return false;
      final insp = insByFacility[f.id];
      if (filter.urgentOnly && (insp?.urgentFlag != true)) return false;
      if (filter.grades.isNotEmpty) {
        if (insp == null || !filter.grades.contains(insp.grade)) return false;
      }
      return true;
    }

    final filtered = facilities.where(matches).toList();

    // Stats.
    final today = DateTime.now();
    final inspectedToday = filtered.where((f) {
      final i = insByFacility[f.id];
      if (i == null) return false;
      return i.datetime.year == today.year &&
          i.datetime.month == today.month &&
          i.datetime.day == today.day;
    }).length;

    final scored = filtered
        .map((f) => insByFacility[f.id]?.totalScore)
        .where((s) => s != null)
        .cast<double>()
        .toList();
    final districtScore = scored.isEmpty
        ? 0
        : (scored.reduce((a, b) => a + b) / scored.length).round();

    final criticalCount = filtered
        .where((f) => insByFacility[f.id]?.grade == Grade.critical)
        .length;
    final urgentCount = filtered
        .where((f) => insByFacility[f.id]?.urgentFlag == true)
        .length;

    // Mandal average scores.
    final scoresByMandal = <String, List<double>>{};
    for (final f in facilities) {
      final i = insByFacility[f.id];
      if (i == null) continue;
      scoresByMandal.putIfAbsent(f.mandalId, () => []).add(i.totalScore);
    }
    final mandalAvgScores = {
      for (final e in scoresByMandal.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length
    };

    final userById = {for (final u in users) u.id: u};

    final statsRow = Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: StatCardRow(
        districtScore: districtScore,
        totalFacilities: filtered.length,
        criticalCount: criticalCount,
        urgentCount: urgentCount,
        inspectedToday: inspectedToday,
      ),
    );

    final isMobile = Responsive.isMobile(context);

    final alertsPanel = widget.mandalScopeId == null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: AlertsPanel(
              facilities: filtered,
              latestByFacility: insByFacility,
            ),
          )
        : const SizedBox.shrink();

    final viewToggle = widget.mandalScopeId == null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: SegmentedButton<_ViewMode>(
              segments: const [
                ButtonSegment(
                    value: _ViewMode.map,
                    icon: Icon(Icons.map, size: 16),
                    label: Text('Map')),
                ButtonSegment(
                    value: _ViewMode.reports,
                    icon: Icon(Icons.table_chart, size: 16),
                    label: Text('Reports')),
                ButtonSegment(
                    value: _ViewMode.trends,
                    icon: Icon(Icons.trending_up, size: 16),
                    label: Text('Trends')),
              ],
              selected: {_viewMode},
              onSelectionChanged: (s) =>
                  setState(() => _viewMode = s.first),
            ),
          )
        : const SizedBox.shrink();

    Widget mainContent;
    switch (_viewMode) {
      case _ViewMode.map:
        mainContent = _mapStack(filtered, insByFacility, userById);
      case _ViewMode.reports:
        mainContent = ReportsTable(
          inspections: inspections,
          facilityMap: {for (final f in facilities) f.id: f},
          userMap: userById,
        );
      case _ViewMode.trends:
        mainContent = TrendChart(inspections: inspections);
    }

    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            statsRow,
            alertsPanel,
            viewToggle,
            Padding(
              padding: const EdgeInsets.all(16),
              child: const FilterPanel(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: mainContent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: MandalBars(
                mandals: mandals,
                scoresByMandalId: mandalAvgScores,
                highlightMandalId: widget.mandalScopeId,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        statsRow,
        alertsPanel,
        viewToggle,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FilterPanel(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: MandalBars(
                            mandals: mandals,
                            scoresByMandalId: mandalAvgScores,
                            highlightMandalId: widget.mandalScopeId,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: mainContent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapStack(
    List<Facility> filtered,
    Map<String, Inspection> insByFacility,
    Map<String, User> userById,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DistrictMap(
            facilities: filtered,
            inspectionsByFacilityId: insByFacility,
            onFacilityTap: (f) => setState(() => _selected = f),
            selected: _selected,
          ),
        ),
        if (_selected != null)
          Positioned(
            top: 12,
            right: 12,
            child: FacilityPopup(
              facility: _selected!,
              inspection: insByFacility[_selected!.id],
              officer: userById[insByFacility[_selected!.id]?.officerId],
              onClose: () => setState(() => _selected = null),
            ),
          ),
      ],
    );
  }
}

class _DataErrorPanel extends StatelessWidget {
  final List<String> errors;
  const _DataErrorPanel({required this.errors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.error_outline,
                      color: Color(0xFFB71C1C), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Failed to load dashboard data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final e in errors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $e',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
