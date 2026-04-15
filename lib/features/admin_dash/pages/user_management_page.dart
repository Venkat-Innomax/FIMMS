import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/user.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (users) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('${users.length} users',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FimmsColors.textMuted)),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add user (demo mode)')),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add User'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final u = users[index];
                  return _UserCard(user: u);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: FimmsColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: FimmsColors.primary.withValues(alpha: 0.1),
              child: Text(
                _initials(user.name),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(user.designation,
                      style: const TextStyle(
                          fontSize: 12, color: FimmsColors.textMuted)),
                ],
              ),
            ),
            _RoleBadge(role: user.role),
            if (user.mandalId != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FimmsColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: FimmsColors.outline),
                ),
                child: Text(user.mandalId!,
                    style: const TextStyle(
                        fontSize: 11, color: FimmsColors.textMuted)),
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit user (demo mode)')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    return name
        .replaceAll(RegExp(r'(Smt\.|Sri|Dr\.)'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0])
        .join()
        .toUpperCase();
  }
}

class _RoleBadge extends StatelessWidget {
  final Role role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      Role.collector => FimmsColors.primary,
      Role.admin => Colors.deepPurple,
      Role.mandalAdmin => Colors.indigo,
      Role.mandalOfficer => Colors.teal,
      Role.fieldOfficer => Colors.brown,
      Role.fieldOfficerHospital => Colors.brown,
      Role.inspectionSupervisor => Colors.orange,
      Role.welfareOfficer => Colors.green,
      Role.dmhoAdmin => Colors.red,
      Role.dyDmhoAdmin => Colors.redAccent,
      Role.departmentAdmin => Colors.blueGrey,
      Role.facilityAdmin => Colors.pink,
      Role.hospitalSuperintendent => Colors.pink,
      Role.studentUser => Colors.grey,
      Role.citizenUser => Colors.grey,
      Role.publicUser => Colors.grey,
      Role.grievanceOfficer => Colors.cyan,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        role.label,
        style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
