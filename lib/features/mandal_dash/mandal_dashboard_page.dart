import 'package:flutter/material.dart';

import '../collector_dash/collector_dashboard_page.dart';

/// Mandal Officer dashboard. Reuses the Collector dashboard scoped to a
/// single mandal — the only meaningful difference is the data filter plus
/// title. Spec §3.1 Mandal Dashboard data scope: "Own mandal only".
class MandalDashboardPage extends StatelessWidget {
  final String mandalId;
  const MandalDashboardPage({super.key, required this.mandalId});

  @override
  Widget build(BuildContext context) {
    return CollectorDashboardPage(
      mandalScopeId: mandalId,
      showMandalFilter: false,
    );
  }
}
