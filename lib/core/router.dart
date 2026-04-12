import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/collector_dash/collector_dashboard_page.dart';
import '../features/collector_dash/widgets/facility_detail_page.dart';
import '../features/field_officer/inspection_page.dart';
import '../features/field_officer/officer_home_page.dart';
import '../features/field_officer/score_summary_page.dart';
import '../features/mandal_dash/mandal_dashboard_page.dart';
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
      final atLogin = state.matchedLocation == '/login';

      if (!signedIn && !atLogin) return '/login';
      if (signedIn && atLogin) return _homeFor(auth);
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
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
        path: '/mandal/:id',
        builder: (context, state) =>
            MandalDashboardPage(mandalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/officer',
        builder: (context, state) => const OfficerHomePage(),
        routes: [
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
        ],
      ),
    ],
  );
});

String _homeFor(User user) {
  switch (user.role) {
    case Role.collector:
    case Role.admin:
    case Role.mandalAdmin:
      return '/collector';
    case Role.mandalOfficer:
      return '/mandal/${user.mandalId ?? 'unknown'}';
    case Role.fieldOfficer:
      return '/officer';
  }
}
