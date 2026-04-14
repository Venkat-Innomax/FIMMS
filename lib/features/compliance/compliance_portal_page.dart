import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/compliance_repository.dart';
import '../../data/repositories/facility_repository.dart';
import '../../models/compliance_item.dart';
import '../../services/mock_auth_service.dart';
import 'widgets/compliance_item_list.dart';
import 'widgets/compliance_status_card.dart';
import 'widgets/status_history_tab.dart';
import 'widgets/welfare_institutions_tab.dart';
import 'widgets/welfare_issues_tab.dart';

final _complianceItemsProvider =
    FutureProvider.family<List<ComplianceItem>, String>(
        (ref, facilityId) async {
  return ref.read(complianceRepositoryProvider).byFacility(facilityId);
});

class CompliancePortalPage extends ConsumerStatefulWidget {
  const CompliancePortalPage({super.key});

  @override
  ConsumerState<CompliancePortalPage> createState() =>
      _CompliancePortalPageState();
}

class _CompliancePortalPageState extends ConsumerState<CompliancePortalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final facilityId = user?.facilityId;

    if (facilityId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compliance Portal')),
        body: const Center(
            child: Text('No facility assigned to this account')),
      );
    }

    final facilityAsync = ref.watch(moduleFacilitiesProvider);
    final itemsAsync = ref.watch(_complianceItemsProvider(facilityId));

    final facilityName = facilityAsync.whenOrNull(
      data: (facilities) {
        final f = facilities.where((f) => f.id == facilityId);
        return f.isNotEmpty ? f.first.name : facilityId;
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(facilityName ?? 'Compliance Portal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'All Items'),
            Tab(text: 'Institutions'),
            Tab(text: 'Issues'),
            Tab(text: 'Status History'),
          ],
          isScrollable: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          return Column(
            children: [
              ComplianceStatusCards(items: items),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ComplianceItemList(
                      items: items
                          .where(
                              (i) => i.status == ComplianceStatus.pending)
                          .toList(),
                      emptyMessage: 'No pending items',
                    ),
                    ComplianceItemList(
                      items: items
                          .where((i) =>
                              i.status == ComplianceStatus.submitted)
                          .toList(),
                      emptyMessage: 'No submitted responses',
                    ),
                    ComplianceItemList(
                      items: items,
                      emptyMessage: 'No compliance items',
                    ),
                    const WelfareInstitutionsTab(),
                    const WelfareIssuesTab(),
                    const StatusHistoryTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
