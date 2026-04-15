import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../../models/user.dart';
import '../../collector_dash/widgets/officer_workload_panel.dart';

class OfficerPerformance extends ConsumerWidget {
  const OfficerPerformance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final usersAsync = ref.watch(usersProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);

    final isLoading = inspectionsAsync.isLoading ||
        usersAsync.isLoading ||
        facilitiesAsync.isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = inspectionsAsync.error ?? usersAsync.error ?? facilitiesAsync.error;
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    final inspections = inspectionsAsync.value ?? <Inspection>[];
    final users = usersAsync.value ?? <User>[];
    final facilities = facilitiesAsync.value ?? <Facility>[];

    final userMap = {for (final u in users) u.id: u};
    final facilityMap = {for (final f in facilities) f.id: f};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: OfficerWorkloadPanel(
        inspections: inspections,
        userMap: userMap,
        facilityMap: facilityMap,
      ),
    );
  }
}
