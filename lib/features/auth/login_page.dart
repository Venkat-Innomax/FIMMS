import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../services/mock_auth_service.dart';
import '../shared_widgets/responsive_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  User? _selected;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final usersAsync = ref.watch(demoUsersProvider);

    final left = _HeroPanel();
    final right = FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                32,
                isMobile ? 32 + MediaQuery.paddingOf(context).top : 32,
                32,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (isMobile) ...[
                  const FimmsBrandMark(fontSize: 20),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Sign in',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Demo build — pick a preset role to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FimmsColors.textMuted,
                      ),
                ),
                const SizedBox(height: 28),
                usersAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Failed to load users: $e'),
                  data: (users) => _GroupedUserList(
                    users: users,
                    selected: _selected,
                    onSelect: (u) => setState(() => _selected = u),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _selected == null
                        ? null
                        : () {
                            // Flipping the auth state fires the router's
                            // refresh listenable; go_router's redirect
                            // callback handles the actual navigation to
                            // the right role home.
                            ref
                                .read(authStateProvider.notifier)
                                .signIn(_selected!);
                          },
                    icon: const Icon(Icons.login),
                    label: const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FimmsColors.surface,
                    border: Border.all(color: FimmsColors.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: FimmsColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a pre-bid demo build. Authentication, audit '
                          'trails, and session management are stubbed.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: FimmsColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: isMobile
          ? right
          : Row(
              children: [
                Expanded(flex: 5, child: left),
                Expanded(flex: 6, child: right),
              ],
            ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FimmsColors.primary, FimmsColors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 30,
                decoration: BoxDecoration(
                  color: FimmsColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Field Inspection Management\n& Monitoring System',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'District Administration\n'
            '${AppConstants.districtName}, ${AppConstants.stateName}',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const Spacer(),
          _FeatureRow(
              icon: Icons.map_outlined, text: 'District-wide GIS dashboard'),
          _FeatureRow(
              icon: Icons.assignment_turned_in_outlined,
              text: 'Structured inspection checklists'),
          _FeatureRow(
              icon: Icons.camera_alt_outlined,
              text: 'Geo-tagged photo evidence'),
          _FeatureRow(
              icon: Icons.verified_outlined,
              text: 'Rule-based verification layer'),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: FimmsColors.secondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role category definitions for grouping users
// ---------------------------------------------------------------------------

class _RoleCategory {
  final String title;
  final String description;
  final Set<Role> roles;
  final bool initiallyExpanded;

  const _RoleCategory({
    required this.title,
    required this.description,
    required this.roles,
    this.initiallyExpanded = false,
  });
}

const _roleCategories = <_RoleCategory>[
  _RoleCategory(
    title: 'District Administration',
    description: 'Top-level district oversight and inspection cell management',
    roles: {Role.collector, Role.admin},
    initiallyExpanded: true,
  ),
  _RoleCategory(
    title: 'Mandal Level',
    description: 'Mandal-level coordination and nodal operations',
    roles: {Role.mandalAdmin, Role.mandalOfficer},
  ),
  _RoleCategory(
    title: 'Field Operations',
    description: 'On-ground inspections, audits, and supervisory checks',
    roles: {Role.fieldOfficer, Role.inspectionSupervisor},
  ),
  _RoleCategory(
    title: 'Facility',
    description: 'Hostel, hospital, and facility-side administration',
    roles: {Role.facilityAdmin},
  ),
  _RoleCategory(
    title: 'Public',
    description: 'Citizen grievance filing and grievance review',
    roles: {Role.publicUser, Role.grievanceOfficer},
  ),
];

// ---------------------------------------------------------------------------
// Grouped user list with expandable sections
// ---------------------------------------------------------------------------

class _GroupedUserList extends StatelessWidget {
  final List<User> users;
  final User? selected;
  final ValueChanged<User> onSelect;

  const _GroupedUserList({
    required this.users,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final category in _roleCategories)
          _buildSection(context, category),
      ],
    );
  }

  Widget _buildSection(BuildContext context, _RoleCategory category) {
    final categoryUsers =
        users.where((u) => category.roles.contains(u.role)).toList();
    if (categoryUsers.isEmpty) return const SizedBox.shrink();

    final hasSelection =
        selected != null && category.roles.contains(selected!.role);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: FimmsColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: hasSelection ? FimmsColors.primary : FimmsColors.outline,
            width: hasSelection ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          // Remove the default divider line that ExpansionTile draws.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: category.initiallyExpanded,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding:
                const EdgeInsets.only(left: 14, right: 14, bottom: 10),
            title: Text(
              category.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FimmsColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
            subtitle: Text(
              category.description,
              style: const TextStyle(
                fontSize: 11,
                color: FimmsColors.textMuted,
              ),
            ),
            children: [
              for (final u in categoryUsers)
                _UserRow(
                  user: u,
                  selected: selected?.id == u.id,
                  onTap: () => onSelect(u),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual user row — selected state now shows a prominent checkmark
// ---------------------------------------------------------------------------

class _UserRow extends StatelessWidget {
  final User user;
  final bool selected;
  final VoidCallback onTap;

  const _UserRow({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.name
        .replaceAll('Smt.', '')
        .replaceAll('Sri', '')
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0])
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? FimmsColors.primary.withValues(alpha: 0.06)
            : FimmsColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? FimmsColors.primary : FimmsColors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? FimmsColors.primary.withValues(alpha: 0.15)
                        : FimmsColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected
                              ? FimmsColors.primary
                              : FimmsColors.textPrimary,
                        ),
                      ),
                      Text(
                        user.designation,
                        style: const TextStyle(
                          fontSize: 11,
                          color: FimmsColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: FimmsColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: FimmsColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: FimmsColors.outline),
                    ),
                    child: Text(
                      user.role.label,
                      style: const TextStyle(
                        color: FimmsColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
