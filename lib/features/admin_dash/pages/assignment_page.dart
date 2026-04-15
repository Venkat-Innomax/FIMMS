import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/assignment.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../../models/user.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  const AssignmentPage({super.key});

  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage> {
  AssignmentStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(assignmentListProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final usersAsync = ref.watch(usersProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
    final users = usersAsync.valueOrNull ?? <User>[];
    final inspections = inspectionsAsync.valueOrNull ?? <Inspection>[];

    final facilityMap = {for (final f in facilities) f.id: f};
    final userMap = {for (final u in users) u.id: u};
    final inspectionMap = {for (final i in inspections) i.id: i};

    var filtered = assignments;
    if (_statusFilter != null) {
      filtered =
          filtered.where((a) => a.status == _statusFilter).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('${filtered.length} assignments',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: FimmsColors.textMuted)),
              const Spacer(),
              _StatusFilter(
                selected: _statusFilter,
                onChanged: (s) => setState(() => _statusFilter = s),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final a = filtered[index];
              final facility = facilityMap[a.facilityId];
              final officer = userMap[a.officerId];
              final inspection = a.inspectionId != null
                  ? inspectionMap[a.inspectionId]
                  : null;
              return _AssignmentCard(
                assignment: a,
                facilityName: facility?.name ?? a.facilityId,
                facilityLocation: facility?.location,
                officerName: officer?.name ?? a.officerId,
                inspection: inspection,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final AssignmentStatus? selected;
  final ValueChanged<AssignmentStatus?> onChanged;
  const _StatusFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final s in AssignmentStatus.values)
          FilterChip(
            label: Text(s.label),
            selected: selected == s,
            onSelected: (_) => onChanged(s),
          ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final String facilityName;
  final LatLng? facilityLocation;
  final String officerName;
  final Inspection? inspection;

  const _AssignmentCard({
    required this.assignment,
    required this.facilityName,
    required this.officerName,
    this.facilityLocation,
    this.inspection,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = assignment.status == AssignmentStatus.completed;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCompleted ? FimmsColors.success.withValues(alpha: 0.4) : FimmsColors.outline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (assignment.isReinspection)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
            // Verify button for completed assignments
            if (isCompleted) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showVerifyDialog(context),
                  icon: const Icon(Icons.verified_user, size: 15),
                  label: const Text('Verify'),
                  style: FilledButton.styleFrom(
                    backgroundColor: FimmsColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVerifyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _VerifyResultsDialog(
        assignment: assignment,
        facilityName: facilityName,
        facilityLocation: facilityLocation,
        officerName: officerName,
        inspection: inspection,
      ),
    );
  }
}

class _VerifyResultsDialog extends StatelessWidget {
  final Assignment assignment;
  final String facilityName;
  final LatLng? facilityLocation;
  final String officerName;
  final Inspection? inspection;

  const _VerifyResultsDialog({
    required this.assignment,
    required this.facilityName,
    required this.facilityLocation,
    required this.officerName,
    required this.inspection,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth > 700 ? 600.0 : screenWidth * 0.92;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: FimmsColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Verify Inspection Results',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(facilityName,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('Officer: $officerName',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),

            // Body
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.6,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: inspection != null
                    ? _buildInspectionResults(context)
                    : _buildNoInspection(),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  if (inspection != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Inspection verified and approved'),
                              backgroundColor: FimmsColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Mark Verified'),
                        style: FilledButton.styleFrom(
                          backgroundColor: FimmsColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchMapsUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  Widget _buildNoInspection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 40, color: FimmsColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No inspection results linked to this assignment yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FimmsColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Assignment ID: ${assignment.id}',
            style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionResults(BuildContext context) {
    final insp = inspection!;
    final df = DateFormat('dd MMM yyyy, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview card
        _SectionHeader(icon: Icons.summarize, title: 'Inspection Overview'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FimmsColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FimmsColors.outline),
          ),
          child: Column(
            children: [
              _InfoRow('Inspection ID', insp.id),
              _InfoRow('Date & Time', df.format(insp.datetime)),
              _InfoRow('Status', insp.status.label),
              _InfoRow('Total Score', '${insp.totalScore.toStringAsFixed(1)} / 100'),
              _InfoRow('Grade', insp.grade.label),
              if (insp.reviewedBy != null)
                _InfoRow('Reviewed By', insp.reviewedBy!),
              if (insp.urgentFlag)
                _InfoRow('Urgent', insp.urgentReason ?? 'Yes',
                    valueColor: FimmsColors.danger),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Grade bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: insp.grade.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: insp.grade.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: insp.grade.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${insp.grade.label} — ${insp.grade.action}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: insp.grade.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Officer's Selfie Verification
        _SectionHeader(icon: Icons.verified_user, title: 'Officer Verification (Selfie)'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FimmsColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FimmsColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FimmsColors.outline),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera, size: 48, color: FimmsColors.textMuted),
                      SizedBox(height: 8),
                      Text(
                        '[Demo] Officer Selfie',
                        style: TextStyle(
                          color: FimmsColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FimmsColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Photo Location: Manjeera Majestic Homes, Kukatpally',
                        style: TextStyle(
                          fontSize: 11,
                          color: FimmsColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open Google Maps to Manjeera Majestic Homes
                    final lat = 17.491294;
                    final lng = 78.393504;
                    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                    _launchMapsUrl(mapsUrl);
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('View Location in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // GPS / Location verification
        _SectionHeader(icon: Icons.location_on, title: 'Location Verification'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FimmsColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FimmsColors.outline),
          ),
          child: Column(
            children: [
              _InfoRow('Inspection GPS',
                  '${insp.gps.latitude.toStringAsFixed(5)}, ${insp.gps.longitude.toStringAsFixed(5)}'),
              if (facilityLocation != null)
                _InfoRow('Facility Location',
                    '${facilityLocation!.latitude.toStringAsFixed(5)}, ${facilityLocation!.longitude.toStringAsFixed(5)}'),
              _InfoRow(
                'Geofence Check',
                insp.geofencePass ? 'PASS' : 'FAIL',
                valueColor:
                    insp.geofencePass ? FimmsColors.success : FimmsColors.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section-wise results
        _SectionHeader(icon: Icons.grading, title: 'Section-wise Results'),
        const SizedBox(height: 8),
        for (final section in insp.sections) ...[
          _SectionResultTile(section: section),
          const SizedBox(height: 6),
        ],

        // Photos
        if (insp.sections.any((s) => s.photoPaths.isNotEmpty)) ...[
          const SizedBox(height: 12),
          _SectionHeader(icon: Icons.photo_library, title: 'Uploaded Photos'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final section in insp.sections)
                for (final photo in section.photoPaths)
                  _PhotoThumbnail(path: photo, sectionTitle: section.title),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FimmsColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FimmsColors.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: FimmsColors.textMuted,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? FimmsColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _SectionResultTile extends StatelessWidget {
  final SectionResult section;
  const _SectionResultTile({required this.section});

  @override
  Widget build(BuildContext context) {
    final pct = section.maxScore > 0
        ? (section.rawScore / section.maxScore * 100)
        : 0.0;
    final grade = GradeX.fromScore(pct);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (section.skipped)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('SKIPPED',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey)),
                  ),
                ),
              Expanded(
                child: Text(
                  section.title.isNotEmpty ? section.title : section.sectionId,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: grade.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${section.rawScore.toStringAsFixed(1)} / ${section.maxScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: grade.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: section.maxScore > 0
                  ? section.rawScore / section.maxScore
                  : 0,
              minHeight: 4,
              backgroundColor: FimmsColors.outline.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(grade.color),
            ),
          ),
          if (section.remarks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Remarks: ${section.remarks}',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: FimmsColors.textMuted,
              ),
            ),
          ],
          if (section.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.photo, size: 12, color: FimmsColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${section.photoPaths.length} photo(s) uploaded',
                  style: const TextStyle(
                      fontSize: 10, color: FimmsColors.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String path;
  final String sectionTitle;
  const _PhotoThumbnail({required this.path, required this.sectionTitle});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$sectionTitle\n$path',
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: FimmsColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FimmsColors.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 28, color: FimmsColors.textMuted),
            const SizedBox(height: 4),
            Text(
              path.split('/').last,
              style: const TextStyle(fontSize: 8, color: FimmsColors.textMuted),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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
      AssignmentStatus.completed => (FimmsColors.success, Icons.check_circle),
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
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
