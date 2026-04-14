import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../data/repositories/facility_repository.dart';
import '../../models/complaint.dart';
import '../../models/facility.dart';
import '../../services/mock_auth_service.dart';
import 'widgets/complaint_card.dart';
import 'widgets/complaint_form.dart';

final _userComplaintsProvider =
    FutureProvider.family<List<Complaint>, String>((ref, userId) async {
  return ref.read(complaintRepositoryProvider).byUser(userId);
});

class GrievancePortalPage extends ConsumerWidget {
  const GrievancePortalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Grievance Portal'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'My Complaints'),
              Tab(icon: Icon(Icons.add_circle_outline), text: 'New Complaint'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(authStateProvider.notifier).signOut(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _MyComplaints(userId: user?.id ?? ''),
            const ComplaintForm(),
          ],
        ),
      ),
    );
  }
}

class _MyComplaints extends ConsumerWidget {
  final String userId;
  const _MyComplaints({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(_userComplaintsProvider(userId));
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);

    return complaintsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (complaints) {
        if (complaints.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 48, color: FimmsColors.textMuted),
                SizedBox(height: 12),
                Text('No complaints lodged yet',
                    style: TextStyle(color: FimmsColors.textMuted)),
                SizedBox(height: 4),
                Text('Use the "New Complaint" tab to file one',
                    style: TextStyle(
                        fontSize: 12, color: FimmsColors.textMuted)),
              ],
            ),
          );
        }

        final facilities =
            facilitiesAsync.valueOrNull ?? <Facility>[];
        final facilityMap = {for (final f in facilities) f.id: f};

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final c = complaints[index];
            return ComplaintCard(
              complaint: c,
              facilityName:
                  facilityMap[c.facilityId]?.name ?? c.facilityId,
            );
          },
        );
      },
    );
  }
}
