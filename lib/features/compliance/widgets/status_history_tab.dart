import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/compliance_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/compliance_item.dart';
import '../../../models/inspection.dart';
import '../../../services/mock_auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: all compliance items for a given facility, sorted newest-first
// ─────────────────────────────────────────────────────────────────────────────

final _facilityComplianceProvider =
    FutureProvider.family<List<ComplianceItem>, String>(
  (ref, facilityId) async {
    final all =
        await ref.read(complianceRepositoryProvider).byFacility(facilityId);
    return all..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// StatusHistoryTab — timeline of all compliance actions for the facility
// ─────────────────────────────────────────────────────────────────────────────

class StatusHistoryTab extends ConsumerWidget {
  const StatusHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final facilityId = user?.facilityId;

    if (facilityId == null) {
      return const Center(
          child: Text('No facility linked to this account.'));
    }

    final itemsAsync = ref.watch(_facilityComplianceProvider(facilityId));
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_toggle_off,
                    size: 48, color: FimmsColors.textMuted),
                const SizedBox(height: 12),
                const Text('No compliance history yet.',
                    style: TextStyle(color: FimmsColors.textMuted)),
              ],
            ),
          );
        }

        // Build inspection map for labels
        final inspMap = <String, Inspection>{};
        inspectionsAsync.whenData((insp) {
          for (final i in insp) {
            inspMap[i.id] = i;
          }
        });

        // Group items by inspectionId
        final grouped = <String, List<ComplianceItem>>{};
        for (final item in items) {
          grouped.putIfAbsent(item.inspectionId, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final entry in grouped.entries) ...[
              _InspectionGroup(
                inspectionId: entry.key,
                items: entry.value,
                inspection: inspMap[entry.key],
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InspectionGroup — collapsible group of timeline entries per inspection
// ─────────────────────────────────────────────────────────────────────────────

class _InspectionGroup extends StatefulWidget {
  final String inspectionId;
  final List<ComplianceItem> items;
  final Inspection? inspection;

  const _InspectionGroup({
    required this.inspectionId,
    required this.items,
    this.inspection,
  });

  @override
  State<_InspectionGroup> createState() => _InspectionGroupState();
}

class _InspectionGroupState extends State<_InspectionGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final insp = widget.inspection;
    final df = DateFormat('d MMM yyyy');
    final label = insp != null
        ? 'Inspection — ${df.format(insp.datetime)}'
        : 'Inspection ${widget.inspectionId}';
    final score = insp?.totalScore;

    return Container(
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Group header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FimmsColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_outlined,
                        size: 18, color: FimmsColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.items.length} compliance item${widget.items.length == 1 ? '' : 's'}'
                          '${score != null ? '  ·  Score: ${score.toStringAsFixed(0)}/100' : ''}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: FimmsColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: FimmsColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Timeline entries
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                children: [
                  for (int i = 0; i < widget.items.length; i++) ...[
                    _TimelineEntry(
                      item: widget.items[i],
                      isLast: i == widget.items.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TimelineEntry — single vertical timeline node
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineEntry extends StatelessWidget {
  final ComplianceItem item;
  final bool isLast;

  const _TimelineEntry({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column: dot + vertical line
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 4),
                _StatusDot(status: item.status),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: FimmsColors.outline,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Content card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardBg(item.status),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _statusColor(item.status)
                          .withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _sectionLabel(item.sectionId),
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        _StatusChip(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Observation
                    Text(item.observation,
                        style: const TextStyle(
                            fontSize: 12,
                            color: FimmsColors.textMuted)),

                    // Response (if any)
                    if (item.facilityResponse != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FimmsColors.success
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: FimmsColors.success
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.reply,
                                size: 13,
                                color: FimmsColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.facilityResponse!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: FimmsColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Timestamps
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 11, color: FimmsColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Raised: ${_fmt(item.createdAt)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: FimmsColors.textMuted),
                        ),
                        if (item.respondedAt != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.check_circle_outline,
                              size: 11,
                              color: FimmsColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Responded: ${_fmt(item.respondedAt!)}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: FimmsColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      DateFormat('d MMM yyyy · h:mm a').format(dt);

  String _sectionLabel(String id) =>
      id.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.substring(1)}';
      }).join(' ');

  Color _statusColor(ComplianceStatus s) => switch (s) {
        ComplianceStatus.pending => FimmsColors.warning,
        ComplianceStatus.submitted => FimmsColors.primary,
        ComplianceStatus.accepted => FimmsColors.success,
        ComplianceStatus.rejected => FimmsColors.danger,
      };

  Color _cardBg(ComplianceStatus s) => switch (s) {
        ComplianceStatus.pending =>
          FimmsColors.warning.withValues(alpha: 0.04),
        ComplianceStatus.submitted =>
          FimmsColors.primary.withValues(alpha: 0.04),
        ComplianceStatus.accepted =>
          FimmsColors.success.withValues(alpha: 0.04),
        ComplianceStatus.rejected =>
          FimmsColors.danger.withValues(alpha: 0.04),
      };
}

class _StatusDot extends StatelessWidget {
  final ComplianceStatus status;
  const _StatusDot({required this.status});

  Color get _color => switch (status) {
        ComplianceStatus.pending => FimmsColors.warning,
        ComplianceStatus.submitted => FimmsColors.primary,
        ComplianceStatus.accepted => FimmsColors.success,
        ComplianceStatus.rejected => FimmsColors.danger,
      };

  IconData get _icon => switch (status) {
        ComplianceStatus.pending => Icons.hourglass_empty,
        ComplianceStatus.submitted => Icons.upload_outlined,
        ComplianceStatus.accepted => Icons.check_circle,
        ComplianceStatus.rejected => Icons.cancel,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, size: 13, color: Colors.white),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ComplianceStatus status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
        ComplianceStatus.pending => FimmsColors.warning,
        ComplianceStatus.submitted => FimmsColors.primary,
        ComplianceStatus.accepted => FimmsColors.success,
        ComplianceStatus.rejected => FimmsColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}
