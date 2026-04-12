import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/inspection.dart';
import '../../../models/user.dart';

class OfficerLoad extends ConsumerWidget {
  final String mandalId;
  const OfficerLoad({super.key, required this.mandalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (users) {
        final inspections = inspectionsAsync.valueOrNull ?? <Inspection>[];
        final officers = users
            .where(
                (u) => u.role == Role.fieldOfficer && u.mandalId == mandalId)
            .toList();

        if (officers.isEmpty) {
          return const Center(
            child: Text('No field officers in this mandal',
                style: TextStyle(color: FimmsColors.textMuted)),
          );
        }

        final maxCount = officers
            .map((o) =>
                inspections.where((i) => i.officerId == o.id).length)
            .fold(0, (a, b) => a > b ? a : b);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Officer Workload',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.textPrimary)),
              const SizedBox(height: 12),
              for (final officer in officers) ...[
                _OfficerBar(
                  name: officer.name,
                  count: inspections
                      .where((i) => i.officerId == officer.id)
                      .length,
                  maxCount: maxCount,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OfficerBar extends StatelessWidget {
  final String name;
  final int count;
  final int maxCount;
  const _OfficerBar(
      {required this.name, required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? count / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            Text('$count inspections',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: FimmsColors.surface,
            color: FimmsColors.primary,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
