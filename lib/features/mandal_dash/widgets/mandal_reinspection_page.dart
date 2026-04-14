import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';

// ---------------------------------------------------------------------------
// Mock reinspection data
// ---------------------------------------------------------------------------

enum _ReinspStatus { pending, approved, done, rejected }

class _ReinspRequest {
  final String id;
  final String facilityName;
  final String facilityType;
  final DateTime originalDate;
  final int issueCount;
  final String requestedBy;
  _ReinspStatus status;

  _ReinspRequest({
    required this.id,
    required this.facilityName,
    required this.facilityType,
    required this.originalDate,
    required this.issueCount,
    required this.requestedBy,
    this.status = _ReinspStatus.pending,
  });
}

final _mockReinspections = <_ReinspRequest>[
  _ReinspRequest(
    id: 'RI-001',
    facilityName: 'SW Boys Hostel, Bhongir',
    facilityType: 'Hostel',
    originalDate: DateTime.now().subtract(const Duration(days: 5)),
    issueCount: 4,
    requestedBy: 'Insp. Suresh Kumar',
  ),
  _ReinspRequest(
    id: 'RI-002',
    facilityName: 'BC Girls Hostel, Ramannapeta',
    facilityType: 'Hostel',
    originalDate: DateTime.now().subtract(const Duration(days: 8)),
    issueCount: 7,
    requestedBy: 'Insp. Ramadevi',
    status: _ReinspStatus.approved,
  ),
  _ReinspRequest(
    id: 'RI-003',
    facilityName: 'PHC Mothkur',
    facilityType: 'Hospital',
    originalDate: DateTime.now().subtract(const Duration(days: 12)),
    issueCount: 2,
    requestedBy: 'Dr. Narasimha Rao',
    status: _ReinspStatus.done,
  ),
  _ReinspRequest(
    id: 'RI-004',
    facilityName: 'CHC Alair',
    facilityType: 'Hospital',
    originalDate: DateTime.now().subtract(const Duration(days: 3)),
    issueCount: 5,
    requestedBy: 'Insp. Padmavathi',
  ),
  _ReinspRequest(
    id: 'RI-005',
    facilityName: 'Min Girls Hostel, Yadagirigutta',
    facilityType: 'Hostel',
    originalDate: DateTime.now().subtract(const Duration(days: 15)),
    issueCount: 1,
    requestedBy: 'Insp. Saidulu',
    status: _ReinspStatus.rejected,
  ),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MandalReinspectionPage extends StatefulWidget {
  final String mandalId;
  const MandalReinspectionPage({super.key, required this.mandalId});

  @override
  State<MandalReinspectionPage> createState() =>
      _MandalReinspectionPageState();
}

class _MandalReinspectionPageState extends State<MandalReinspectionPage> {
  final _requests = List<_ReinspRequest>.from(_mockReinspections);

  void _approve(String id) {
    setState(() {
      final r = _requests.firstWhere((r) => r.id == id);
      r.status = _ReinspStatus.approved;
    });
    _showSnack('Reinspection approved', FimmsColors.success);
  }

  void _reject(String id) {
    setState(() {
      final r = _requests.firstWhere((r) => r.id == id);
      r.status = _ReinspStatus.rejected;
    });
    _showSnack('Reinspection rejected', FimmsColors.danger);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _requests.where((r) => r.status == _ReinspStatus.pending).length;

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: FimmsColors.surface,
          child: Row(
            children: [
              _StatPill(label: 'Pending', count: pending, color: FimmsColors.warning),
              const SizedBox(width: 10),
              _StatPill(
                  label: 'Approved',
                  count: _requests
                      .where((r) => r.status == _ReinspStatus.approved)
                      .length,
                  color: FimmsColors.primary),
              const SizedBox(width: 10),
              _StatPill(
                  label: 'Done',
                  count: _requests
                      .where((r) => r.status == _ReinspStatus.done)
                      .length,
                  color: FimmsColors.success),
            ],
          ),
        ),
        Expanded(
          child: _requests.isEmpty
              ? const Center(
                  child: Text('No reinspection requests',
                      style: TextStyle(color: FimmsColors.textMuted)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final r = _requests[index];
                    return _ReinspCard(
                      request: r,
                      onApprove: r.status == _ReinspStatus.pending
                          ? () => _approve(r.id)
                          : null,
                      onReject: r.status == _ReinspStatus.pending
                          ? () => _reject(r.id)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ReinspCard extends StatelessWidget {
  final _ReinspRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  const _ReinspCard(
      {required this.request, this.onApprove, this.onReject});

  Color get _statusColor => switch (request.status) {
        _ReinspStatus.pending => FimmsColors.warning,
        _ReinspStatus.approved => FimmsColors.primary,
        _ReinspStatus.done => FimmsColors.success,
        _ReinspStatus.rejected => FimmsColors.danger,
      };

  String get _statusLabel => switch (request.status) {
        _ReinspStatus.pending => 'Pending',
        _ReinspStatus.approved => 'Approved',
        _ReinspStatus.done => 'Done',
        _ReinspStatus.rejected => 'Rejected',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.facilityName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              _StatusChip(label: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            children: [
              _MetaText(Icons.date_range_outlined,
                  DateFormat('d MMM yyyy').format(request.originalDate)),
              _MetaText(Icons.warning_amber_outlined,
                  '${request.issueCount} issue${request.issueCount != 1 ? 's' : ''}'),
              _MetaText(Icons.person_outline, request.requestedBy),
              _MetaText(Icons.business_outlined, request.facilityType),
            ],
          ),
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FimmsColors.danger,
                        side: BorderSide(
                            color: FimmsColors.danger.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                if (onApprove != null && onReject != null)
                  const SizedBox(width: 10),
                if (onApprove != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaText(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: FimmsColors.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 11, color: FimmsColors.textMuted)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
