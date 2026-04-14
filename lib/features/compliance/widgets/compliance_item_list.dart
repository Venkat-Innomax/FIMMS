import 'package:flutter/material.dart';

import '../../../models/compliance_item.dart';
import '../../shared_widgets/empty_state.dart';
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
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: emptyMessage,
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
