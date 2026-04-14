import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../services/face_verification_service.dart';
import '../../services/mock_auth_service.dart';
import '../../services/photo_capture_service.dart';
import '../../services/profile_photo_provider.dart';
import '../shared_widgets/grade_chip.dart';
import '../shared_widgets/notification_bell.dart';
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
      actions: const [NotificationBell()],
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

class _ProfileTab extends ConsumerStatefulWidget {
  final User? officer;
  const _ProfileTab({required this.officer});

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  bool _capturing = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.officer;
    final profileState = ref.watch(profilePhotoProvider);

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

              // ── Profile photo card ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FimmsColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: profileState.isSet
                        ? FimmsColors.gradeExcellent.withValues(alpha: 0.5)
                        : FimmsColors.outline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.face_retouching_natural,
                            size: 16, color: FimmsColors.textMuted),
                        const SizedBox(width: 8),
                        const Text(
                          'PROFILE PHOTO',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: FimmsColors.textMuted,
                          ),
                        ),
                        if (profileState.isSet) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: FimmsColors.gradeExcellent
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: FimmsColors.gradeExcellent
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 11,
                                    color: FimmsColors.gradeExcellent),
                                SizedBox(width: 3),
                                Text(
                                  'SET',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: FimmsColors.gradeExcellent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPhotoSection(profileState),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Identity info card ────────────────────────────────────────
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

  // ── Photo section builder ─────────────────────────────────────────────────

  Widget _buildPhotoSection(ProfilePhotoState profileState) {
    // ── Photo already set → read-only avatar ─────────────────────────────
    if (profileState.isSet) {
      return Row(
        children: [
          _ProfileAvatar(path: profileState.photoPath),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.verified_user,
                        size: 16, color: FimmsColors.gradeExcellent),
                    SizedBox(width: 6),
                    Text(
                      'Identity Registered',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: FimmsColors.gradeExcellent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Your profile photo is registered and cannot be changed. '  
                  'It is used to verify your identity before each inspection.',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: FimmsColors.textMuted,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── Web: mobile-only notice ───────────────────────────────────────────
    if (kIsWeb) {
      return Column(
        children: [
          const _ProfileAvatar(path: null),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FimmsColors.gradeAverage.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: FimmsColors.gradeAverage.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: const [
                Icon(Icons.phone_android_outlined,
                    color: FimmsColors.gradeAverage, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile photo can only be set from the mobile app. '
                    'Open FIMMS on your Android or iOS device to register '
                    'your profile selfie.',
                    style: TextStyle(
                        fontSize: 12, color: FimmsColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── Mobile: take selfie button ────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _ProfileAvatar(path: null)),
        const SizedBox(height: 14),
        const Text(
          'You must register your profile photo once before you can conduct '
          'inspections. Your selfie is used to verify your identity via '
          'offline face recognition.',
          style: TextStyle(fontSize: 12, color: FimmsColors.textMuted),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _capturing ? null : _takeSelfie,
            icon: _capturing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.camera_front),
            label: Text(_capturing ? 'Processing…' : 'Take Profile Selfie'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '• Camera only — no photo uploads allowed\n'
          '• This action can only be performed once',
          style: TextStyle(fontSize: 11, color: FimmsColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _takeSelfie() async {
    setState(() => _capturing = true);
    try {
      final captureSvc = ref.read(photoCaptureServiceProvider);
      final path = await captureSvc.capture();
      if (path == null || !mounted) return;

      // Extract face embedding
      final faceSvc = ref.read(faceVerificationServiceProvider);
      final embedding = await faceSvc.extractEmbedding(path);

      if (!mounted) return;

      await ref.read(profilePhotoProvider.notifier).setPhoto(
            path: path,
            embedding: embedding,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.white),
                SizedBox(width: 10),
                Text('Profile photo registered successfully.'),
              ],
            ),
            backgroundColor: FimmsColors.gradeExcellent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
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

/// Circular avatar for the profile photo section.
/// Shows the captured selfie when [path] is given, otherwise a placeholder.
class _ProfileAvatar extends StatelessWidget {
  final String? path;
  const _ProfileAvatar({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    const double size = 88;
    Widget inner;

    if (path == null) {
      // Placeholder
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: FimmsColors.primary.withValues(alpha: 0.07),
          border: Border.all(color: FimmsColors.outline, width: 2),
        ),
        child: const Icon(Icons.person_outline,
            size: 44, color: FimmsColors.textMuted),
      );
    } else if (path!.startsWith('sample:')) {
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: FimmsColors.primary.withValues(alpha: 0.1),
          border: Border.all(
              color: FimmsColors.gradeExcellent.withValues(alpha: 0.6), width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face, size: 38, color: FimmsColors.primary),
            Text('SAMPLE',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.primary)),
          ],
        ),
      );
    } else if (!kIsWeb && File(path!).existsSync()) {
      inner = Container(
        width: size,
        height: size,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: FimmsColors.gradeExcellent.withValues(alpha: 0.6), width: 2),
        ),
        child: Image.file(File(path!), fit: BoxFit.cover),
      );
    } else {
      // Fallback
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: FimmsColors.surface,
          border: Border.all(color: FimmsColors.outline, width: 2),
        ),
        child: const Icon(Icons.person, size: 44, color: FimmsColors.textMuted),
      );
    }

    return Stack(
      children: [
        inner,
        if (path != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: FimmsColors.gradeExcellent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, size: 14, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

