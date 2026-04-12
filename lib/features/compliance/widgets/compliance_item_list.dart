import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/compliance_item.dart';
import 'observation_card.dart';

class ComplianceItemList extends StatelessWidget {
  final List<ComplianceItem> items;
  final String emptyMessage;

  const ComplianceItemList({
    super.key,
    required this.items,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 48, color: FimmsColors.textMuted),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: const TextStyle(color: FimmsColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => ObservationCard(item: items[index]),
    );
  }
}
