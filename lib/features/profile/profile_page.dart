import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/user.dart';
import '../../services/mock_auth_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _designationCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _designationCtrl = TextEditingController(text: user?.designation ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final initials = user.name
        .replaceAll('Smt.', '')
        .replaceAll('Sri', '')
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0])
        .join()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 16,
                  color: Colors.white),
              label: const Text('Edit',
                  style: TextStyle(color: Colors.white)),
            )
          else
            TextButton.icon(
              onPressed: () {
                setState(() => _editing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated (demo — changes not persisted)'),
                    backgroundColor: FimmsColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined, size: 16,
                  color: Colors.white),
              label: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [FimmsColors.primary, FimmsColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.designation,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _RoleChip(role: user.role),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Editable details
                _SectionCard(
                  title: 'Personal Details',
                  icon: Icons.person_outline,
                  children: [
                    _editing
                        ? TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          )
                        : _InfoRow(label: 'Full Name', value: user.name),
                    const SizedBox(height: 12),
                    _editing
                        ? TextField(
                            controller: _designationCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Designation',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          )
                        : _InfoRow(
                            label: 'Designation', value: user.designation),
                  ],
                ),

                const SizedBox(height: 12),

                // Role & access
                _SectionCard(
                  title: 'Role & Access',
                  icon: Icons.badge_outlined,
                  children: [
                    _InfoRow(label: 'Role', value: user.role.label),
                    if (user.mandalId != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Mandal',
                        value: _cap(user.mandalId!),
                      ),
                    ],
                    if (user.facilityId != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                          label: 'Facility', value: user.facilityId!),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Account
                _SectionCard(
                  title: 'Account',
                  icon: Icons.manage_accounts_outlined,
                  children: [
                    _InfoRow(label: 'User ID', value: user.id),
                    if (user.username != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Mobile', value: user.username!),
                    ],
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Password', value: '••••••••'),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authStateProvider.notifier).signOut();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FimmsColors.danger,
                      side: const BorderSide(color: FimmsColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'FIMMS v1.0 — Pre-bid Demo',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: FimmsColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _RoleChip extends StatelessWidget {
  final Role role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: FimmsColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FimmsColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: FimmsColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
