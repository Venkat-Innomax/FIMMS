import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin_dash/admin_dashboard_page.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/login_page.dart';
import '../features/complaint/citizen_complaint_page.dart';
import '../features/complaint/student_complaint_page.dart';
import '../features/grievance/grievance_portal_page.dart';
import '../features/grievance_admin/grievance_admin_page.dart';
import '../features/collector_dash/collector_dashboard_page.dart';
import '../features/compliance/compliance_portal_page.dart';
import '../features/collector_dash/widgets/facility_detail_page.dart';
import '../features/dept_admin_dash/dept_admin_dashboard_page.dart';
import '../features/dmho_dash/dmho_dashboard_page.dart';
import '../features/field_officer/inspection_history_page.dart';
import '../features/field_officer/inspection_page.dart';
import '../features/field_officer/institution_preview_page.dart';
import '../features/field_officer/officer_home_page.dart';
import '../features/field_officer/score_summary_page.dart';
import '../features/mandal_dash/mandal_dashboard_page.dart';
import '../features/nodal_dash/nodal_dashboard_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/profile/profile_page.dart';
import '../features/supervisor_dash/supervisor_dashboard_page.dart';
import '../features/welfare_dash/welfare_officer_page.dart';
import '../models/user.dart';
import '../services/mock_auth_service.dart';

/// `ChangeNotifier` bridge that lets `go_router` react to auth changes.
///
/// Listens to [authStateProvider] via `ref.listen` and fires
/// [notifyListeners] on every change. Because this listens through the
/// provider rather than being recreated on every change, the enclosing
/// [routerProvider] can stay stable — the `GoRouter` instance is built
/// exactly once per app session.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<User?>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// Stable [GoRouter] instance. Do NOT add `ref.watch` calls here — the
/// router must be constructed exactly once so `MaterialApp.router` never
/// sees a swapped `routerConfig` at runtime.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final signedIn = auth != null;
      final loc = state.matchedLocation;
      final isPublicRoute = loc == '/login' || loc == '/forgot-password';

      if (!signedIn && !isPublicRoute) return '/login';
      if (signedIn && loc == '/login') return _homeFor(auth);
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // ── Government Internal ──────────────────────────────────

      GoRoute(
        path: '/collector',
        builder: (context, state) => const CollectorDashboardPage(),
        routes: [
          GoRoute(
            path: 'facility/:id',
            builder: (context, state) =>
                FacilityDetailPage(facilityId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/nodal',
        builder: (context, state) => const NodalDashboardPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/mandal/:id',
        builder: (context, state) =>
            MandalDashboardPage(mandalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/supervisor',
        builder: (context, state) => const SupervisorDashboardPage(),
      ),
      GoRoute(
        path: '/officer',
        builder: (context, state) => const OfficerHomePage(),
        routes: [
          GoRoute(
            path: 'institution/:id',
            builder: (context, state) => InstitutionPreviewPage(
                facilityId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'inspect/:id',
            builder: (context, state) =>
                InspectionPage(assignmentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'inspect/:id/submitted',
            builder: (context, state) => ScoreSummaryPage(
              inspectionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const InspectionHistoryPage(),
          ),
        ],
      ),

      // ── Health / Hospital ────────────────────────────────────

      GoRoute(
        path: '/dmho',
        builder: (context, state) => const DmhoDashboardPage(),
      ),

      // ── Department Admin ─────────────────────────────────────

      GoRoute(
        path: '/dept-admin',
        builder: (context, state) => const DeptAdminDashboardPage(),
      ),

      // ── Welfare Officer ──────────────────────────────────────

      GoRoute(
        path: '/welfare',
        builder: (context, state) => const WelfareOfficerPage(),
      ),

      // ── Facility-Side ────────────────────────────────────────

      GoRoute(
        path: '/compliance',
        builder: (context, state) => const CompliancePortalPage(),
      ),

      // ── Grievance-Side ───────────────────────────────────────

      GoRoute(
        path: '/grievance',
        builder: (context, state) => const GrievancePortalPage(),
      ),
      GoRoute(
        path: '/grievance-admin',
        builder: (context, state) => const GrievanceAdminPage(),
      ),

      // ── Complaint Flows ──────────────────────────────────────

      GoRoute(
        path: '/complaint/hostel',
        builder: (context, state) => const StudentComplaintPage(),
      ),
      GoRoute(
        path: '/complaint/hospital',
        builder: (context, state) => const CitizenComplaintPage(),
      ),
    ],
  );
});

String _homeFor(User user) {
  switch (user.role) {
    case Role.collector:
      return '/collector';
    case Role.admin:
      return '/admin';
    case Role.mandalAdmin:
      return '/nodal';
    case Role.mandalOfficer:
      return '/mandal/${user.mandalId ?? 'unknown'}';
    case Role.fieldOfficer:
      return '/officer';
    case Role.fieldOfficerHospital:
      return '/officer';
    case Role.inspectionSupervisor:
      return '/supervisor';
    case Role.welfareOfficer:
      return '/welfare';
    case Role.dmhoAdmin:
      return '/dmho';
    case Role.dyDmhoAdmin:
      return '/dmho';
    case Role.departmentAdmin:
      return '/dept-admin';
    case Role.facilityAdmin:
      return '/compliance';
    case Role.hospitalSuperintendent:
      return '/compliance';
    case Role.studentUser:
      return '/complaint/hostel';
    case Role.citizenUser:
      return '/complaint/hospital';
    case Role.publicUser:
      return '/grievance';
    case Role.grievanceOfficer:
      return '/grievance-admin';
  }
}

/// Placeholder page for dashboards not yet implemented.
/// Each branch will replace the relevant stub with a real page.
class _StubPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _StubPage({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Sign out — the router redirect handles navigation back to login.
              ProviderScope.containerOf(context)
                  .read(authStateProvider.notifier)
                  .signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coming soon — implementation in progress',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
