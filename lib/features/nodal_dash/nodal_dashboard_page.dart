import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/mock_auth_service.dart';
import 'widgets/approval_card.dart';
import 'widgets/dy_dmho_facility_summary.dart';
import 'widgets/escalation_queue.dart';
import 'widgets/non_compliant_list.dart';

class NodalDashboardPage extends ConsumerWidget {
  const NodalDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nodal Officer Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.warning_amber), text: 'Escalations'),
              Tab(icon: Icon(Icons.gpp_bad), text: 'Non-Compliant'),
              Tab(icon: Icon(Icons.approval), text: 'Approvals'),
              Tab(
                  icon: Icon(Icons.local_hospital_outlined),
                  text: 'Facility Summary'),
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
        body: const TabBarView(
          children: [
            EscalationQueue(),
            NonCompliantList(),
            ApprovalList(),
            DyDmhoFacilitySummary(),
          ],
        ),
      ),
    );
  }
}
