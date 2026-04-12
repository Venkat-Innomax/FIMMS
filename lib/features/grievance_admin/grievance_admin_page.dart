import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/complaint_repository.dart';
import '../../data/repositories/facility_repository.dart';
import '../../models/complaint.dart';
import '../../models/facility.dart';
import '../../services/mock_auth_service.dart';
import 'widgets/intake_queue.dart';

final _allComplaintsProvider = FutureProvider<List<Complaint>>((ref) async {
  return ref.read(complaintRepositoryProvider).loadAll();
});

class GrievanceAdminPage extends ConsumerWidget {
  const GrievanceAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(_allComplaintsProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Grievance Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inbox), text: 'Inbox'),
              Tab(icon: Icon(Icons.pending), text: 'In Progress'),
              Tab(icon: Icon(Icons.check_circle), text: 'Resolved'),
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
        body: complaintsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (complaints) {
            final facilities =
                facilitiesAsync.valueOrNull ?? <Facility>[];
            final facilityMap = {for (final f in facilities) f.id: f};

            final inbox = complaints
                .where((c) =>
                    c.status == ComplaintStatus.submitted ||
                    c.status == ComplaintStatus.underReview)
                .toList();
            final inProgress = complaints
                .where((c) =>
                    c.status == ComplaintStatus.assigned ||
                    c.status == ComplaintStatus.inProgress)
                .toList();
            final resolved = complaints
                .where((c) =>
                    c.status == ComplaintStatus.resolved ||
                    c.status == ComplaintStatus.closed)
                .toList();

            return TabBarView(
              children: [
                IntakeQueue(
                    complaints: inbox, facilityMap: facilityMap),
                IntakeQueue(
                    complaints: inProgress, facilityMap: facilityMap),
                IntakeQueue(
                    complaints: resolved, facilityMap: facilityMap),
              ],
            );
          },
        ),
      ),
    );
  }
}
