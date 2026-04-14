import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/mock_auth_service.dart';
import 'widgets/review_queue.dart';
import 'widgets/officer_performance.dart';

class SupervisorDashboardPage extends ConsumerWidget {
  const SupervisorDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inspection Supervisor'),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(icon: Icon(Icons.rate_review), text: 'Review Queue'),
              Tab(icon: Icon(Icons.analytics), text: 'Performance'),
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
            ReviewQueue(),
            OfficerPerformance(),
          ],
        ),
      ),
    );
  }
}
