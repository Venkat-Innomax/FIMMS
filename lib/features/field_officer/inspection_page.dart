import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/repositories/facility_repository.dart';
import '../../data/repositories/form_schema_repository.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../models/facility.dart';
import '../../models/form_schema.dart';
import '../../models/inspection.dart';
import '../../services/geolocation_service.dart';
import '../../services/inspection_validator.dart';
import '../../services/mock_auth_service.dart';
import '../../services/scoring_engine.dart';
import '../inspection_form/inspection_form_notifier.dart';
import '../inspection_form/section_card.dart';
import '../inspection_form/widgets/selfie_gate.dart';

/// Full inspection flow: header (auto-captured fields), urgent toggle,
/// section stepper rendered by the schema-driven engine, and submit.
class InspectionPage extends ConsumerStatefulWidget {
  final String assignmentId; // facility id
  const InspectionPage({super.key, required this.assignmentId});

  @override
  ConsumerState<InspectionPage> createState() => _InspectionPageState();
}

class _InspectionPageState extends ConsumerState<InspectionPage> {
  Facility? _facility;
  FormSchema? _schema;
  GpsFix? _gpsFix;
  bool _loading = true;
  String? _loadError;
  final _urgentReasonCtrl = TextEditingController();

  /// Whether the selfie gate has been successfully passed for this session.
  bool _faceVerified = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _urgentReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final facility = await ref
          .read(facilityRepositoryProvider)
          .facilityById(widget.assignmentId);
      if (facility == null) {
        setState(() {
          _loadError = 'Facility ${widget.assignmentId} not found';
          _loading = false;
        });
        return;
      }
      final schemaRepo = ref.read(formSchemaRepositoryProvider);
      final schema = facility.type == FacilityType.hostel
          ? await schemaRepo.hostelSchema()
          : await schemaRepo.hospitalSchema();
      final geoSvc = ref.read(geolocationServiceProvider);
      final fix = await geoSvc.currentFix(fallback: facility.location);
      final distance = geoSvc.distanceMeters(fix.position, facility.location);
      final geofencePass = distance <= AppConstants.geofenceRadiusMeters;
      setState(() {
        _facility = facility;
        _schema = schema;
        _gpsFix = fix;
        _loading = false;
      });
      if (!geofencePass && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showGeofenceBlockedDialog(facility, distance);
        });
      }
    } catch (e) {
      setState(() {
        _loadError = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null || _facility == null || _schema == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection')),
        body: Center(child: Text(_loadError ?? 'Failed to load')),
      );
    }

    final facility = _facility!;
    final schema = _schema!;
    final user = ref.watch(authStateProvider);
    final state = ref.watch(inspectionFormProvider(schema));
    final notifier = ref.read(inspectionFormProvider(schema).notifier);
    final geo = ref.read(geolocationServiceProvider);

    final distance = _gpsFix == null
        ? null
        : geo.distanceMeters(_gpsFix!.position, facility.location);
    final geofencePass =
        distance != null && distance <= AppConstants.geofenceRadiusMeters;

    // Compute section completion for progress indicator.
    final totalSections = schema.sections.length;
    int completedSections = 0;
    for (final section in schema.sections) {
      if (state.skippedSections.contains(section.id)) {
        completedSections++;
        continue;
      }
      final sectionFields = section.fields
          .where((f) => f.isVisibleFor(facility.subType))
          .toList();
      if (sectionFields.isEmpty) {
        completedSections++;
        continue;
      }
      final allAnswered = sectionFields.every(
        (f) => state.responses.containsKey('${section.id}.${f.id}'),
      );
      if (allAnswered) completedSections++;
    }
    final progress =
        totalSections > 0 ? completedSections / totalSections : 0.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/officer'),
        ),
        title: Text(facility.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: FimmsColors.primary.withValues(alpha: 0.2),
            valueColor:
                AlwaysStoppedAnimation<Color>(completedSections == totalSections
                    ? FimmsColors.gradeExcellent
                    : FimmsColors.secondary),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(
                facility: facility,
                officerName: user?.name ?? '—',
                gpsFix: _gpsFix,
                distanceMeters: distance,
                geofencePass: geofencePass,
              ),
              const SizedBox(height: 14),

              // ── Selfie identity gate ─────────────────────────────────────
              // Shown regardless of geofence pass state; the gate itself
              // displays appropriate messaging when geofence hasn't passed.
              SelfieGate(
                onVerified: () => setState(() => _faceVerified = true),
              ),
              const SizedBox(height: 14),

              // ── Form body — locked until selfie gate passes ───────────────
              IgnorePointer(
                ignoring: !_faceVerified,
                child: AnimatedOpacity(
                  opacity: _faceVerified ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UrgentSection(
                        flag: state.urgentFlag,
                        controller: _urgentReasonCtrl,
                        onToggle: (v) {
                          notifier.setUrgent(
                              flag: v, reason: _urgentReasonCtrl.text);
                        },
                        onReasonChanged: (v) =>
                            notifier.setUrgent(flag: true, reason: v),
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < schema.sections.length; i++)
                        SectionCard(
                          schema: schema,
                          section: schema.sections[i],
                          subType: facility.subType,
                          index: i,
                        ),
                      const SizedBox(height: 16),
                      _SubmitBar(
                        onSubmit: () =>
                            _submit(facility, schema, geofencePass, user?.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGeofenceBlockedDialog(Facility facility, double distanceMeters) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.location_off,
          color: FimmsColors.gradeCritical,
          size: 44,
        ),
        title: const Text(
          'Outside Geo-fence Area',
          textAlign: TextAlign.center,
        ),
        content: Text(
          'You are ${distanceMeters.round()} m away from ${facility.name}.\n\n'
          'You must be within ${AppConstants.geofenceRadiusMeters.round().toInt()} m of the facility to open the inspection form.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: FimmsColors.gradeCritical,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/officer');
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    Facility facility,
    FormSchema schema,
    bool geofencePass,
    String? officerId,
  ) async {
    final state = ref.read(inspectionFormProvider(schema));
    final validation = InspectionValidator.validate(
      schema: schema,
      responses: state.responses,
      remarksBySection: state.remarksBySection,
      photosBySection: state.photosBySection,
      skippedSections: state.skippedSections,
      subType: facility.subType,
      urgentFlag: state.urgentFlag,
      urgentReason: state.urgentReason,
      geofencePassed: geofencePass,
    );

    if (!validation.passed) {
      _showIssues(validation.issues);
      return;
    }

    final scoring = ScoringEngine.compute(
      schema: schema,
      responses: state.responses,
      subType: facility.subType,
      skippedSections: state.skippedSections,
    );

    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final inspection = Inspection(
      id: id,
      facilityId: facility.id,
      officerId: officerId ?? 'unknown',
      datetime: DateTime.now(),
      gps: _gpsFix?.position ?? facility.location,
      geofencePass: geofencePass,
      urgentFlag: state.urgentFlag,
      urgentReason: state.urgentReason,
      sections: const [],
      totalScore: scoring.totalOutOf100,
      grade: scoring.grade,
    );

    ref.read(inspectionRepositoryProvider).addLocal(inspection);
    ref.invalidate(inspectionsProvider);

    if (!mounted) return;
    context.go(
      '/officer/inspect/${facility.id}/submitted',
      extra: scoring,
    );
  }

  void _showIssues(List issues) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.error_outline,
                      color: FimmsColors.gradeCritical),
                  SizedBox(width: 8),
                  Text(
                    'Cannot submit yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Resolve the following before submitting:',
                style: TextStyle(
                    fontSize: 12, color: FimmsColors.textMuted),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final issue in issues)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4, right: 8),
                              child: Icon(Icons.circle,
                                  size: 6, color: FimmsColors.textMuted),
                            ),
                            Expanded(
                              child: Text(
                                issue.message,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Facility facility;
  final String officerName;
  final GpsFix? gpsFix;
  final double? distanceMeters;
  final bool geofencePass;

  const _HeaderCard({
    required this.facility,
    required this.officerName,
    required this.gpsFix,
    required this.distanceMeters,
    required this.geofencePass,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatter = DateFormat('EEE, d MMM yyyy · h:mm a');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FimmsColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  facility.type.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: FimmsColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  facility.subTypeLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: FimmsColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            facility.name,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            '${facility.village}, ${_cap(facility.mandalId)} Mandal',
            style: const TextStyle(
              fontSize: 12,
              color: FimmsColors.textMuted,
            ),
          ),
          const Divider(height: 20),
          _MetaRow(
            icon: Icons.person_outline,
            label: 'Officer',
            value: officerName,
          ),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: formatter.format(now),
          ),
          _MetaRow(
            icon: Icons.my_location,
            label: 'GPS',
            value: gpsFix == null
                ? 'Acquiring…'
                : '${gpsFix!.position.latitude.toStringAsFixed(5)}, ${gpsFix!.position.longitude.toStringAsFixed(5)}'
                    '${gpsFix!.simulated ? " (simulated)" : ""}'
                    ' · ±${gpsFix!.accuracyMeters.round()}m',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _GeofenceChip(
                passed: geofencePass,
                distanceMeters: distanceMeters,
              ),
              const SizedBox(width: 8),
              if (gpsFix != null &&
                  gpsFix!.accuracyMeters >
                      AppConstants.gpsAccuracyWarningMeters)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        FimmsColors.gradeAverage.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: FimmsColors.gradeAverage),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12, color: FimmsColors.gradeAverage),
                      SizedBox(width: 4),
                      Text(
                        'Low GPS accuracy',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: FimmsColors.gradeAverage,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _GeofenceChip extends StatelessWidget {
  final bool passed;
  final double? distanceMeters;
  const _GeofenceChip({required this.passed, required this.distanceMeters});

  @override
  Widget build(BuildContext context) {
    final color = passed ? FimmsColors.gradeExcellent : FimmsColors.gradeCritical;
    final label = passed
        ? 'Geo-fence PASS${distanceMeters != null ? " · ${distanceMeters!.round()}m" : ""}'
        : 'Geo-fence FAIL${distanceMeters != null ? " · ${distanceMeters!.round()}m" : ""}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            passed ? Icons.check_circle_outline : Icons.error_outline,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: FimmsColors.textMuted),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: FimmsColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentSection extends StatelessWidget {
  final bool flag;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onReasonChanged;

  const _UrgentSection({
    required this.flag,
    required this.controller,
    required this.onToggle,
    required this.onReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: flag
            ? FimmsColors.secondary.withValues(alpha: 0.08)
            : FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flag ? FimmsColors.secondary : FimmsColors.outline,
          width: flag ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 18,
                color: flag ? FimmsColors.secondary : FimmsColors.textMuted,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Urgent / emergency flag',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: flag,
                onChanged: onToggle,
                activeThumbColor: FimmsColors.secondary,
              ),
            ],
          ),
          if (flag) ...[
            const SizedBox(height: 8),
            const Text(
              'Reason *',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: FimmsColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText:
                    'Describe the urgent observation or emergency…',
              ),
              onChanged: onReasonChanged,
            ),
          ] else
            const Text(
              'Toggle only for emergencies that require immediate '
              'Collector escalation. A reason is mandatory.',
              style: TextStyle(
                fontSize: 11.5,
                color: FimmsColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final VoidCallback onSubmit;
  const _SubmitBar({required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.check_circle_outline),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Submit Inspection'),
            ),
          ),
        ),
      ],
    );
  }
}
