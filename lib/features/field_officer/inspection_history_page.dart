import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';

class InspectionHistoryPage extends ConsumerWidget {
  const InspectionHistoryPage({super.key});

  static const _history = [
    (
      'i01',
      'Govt BC BH Mothkur',
      'Oct 12, 2026',
      'Submitted',
      '78',
      Colors.teal,
    ),
    (
      'i02',
      'KGBV Bhongir',
      'Oct 05, 2026',
      'Reviewed',
      '65',
      Colors.blue,
    ),
    (
      'i06',
      'Govt BC BH College Alair',
      'Sep 28, 2026',
      'Escalated',
      '42',
      Colors.red,
    ),
    (
      'i07',
      'Govt SCDD Boys Hostel Kolanpaka',
      'Sep 20, 2026',
      'Resolved',
      '81',
      Colors.green,
    ),
    (
      'i08',
      'Govt SCDD Girls Hostel Aler',
      'Sep 12, 2026',
      'Reviewed',
      '70',
      Colors.blue,
    ),
    (
      'i09',
      'Govt ST Boys Hostel Alair',
      'Sep 01, 2026',
      'Submitted',
      '55',
      Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inspection History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: FimmsColors.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                _SummaryChip(label: 'Total', value: '${_history.length}', color: FimmsColors.primary),
                const SizedBox(width: 16),
                _SummaryChip(
                    label: 'Submitted',
                    value: '${_history.where((h) => h.$5 == 'Submitted' || h.$5 == 'Reviewed').length}',
                    color: Colors.teal),
                const SizedBox(width: 16),
                _SummaryChip(
                    label: 'Escalated',
                    value: '${_history.where((h) => h.$5 == 'Escalated').length}',
                    color: Colors.red),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final (id, name, date, status, score, color) = _history[i];
                return _HistoryCard(
                  id: id,
                  facilityName: name,
                  date: date,
                  status: status,
                  score: score,
                  color: color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String id;
  final String facilityName;
  final String date;
  final String status;
  final String score;
  final Color color;

  const _HistoryCard({
    required this.id,
    required this.facilityName,
    required this.date,
    required this.status,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(facilityName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: FimmsColors.textMuted),
                const SizedBox(width: 4),
                Text(date,
                    style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
                const Spacer(),
                Text('Score: ',
                    style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
                Text('$score / 100',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: FimmsColors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            _ScoreBar(score: int.tryParse(score) ?? 0),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View inspection #$id — not wired in demo'))),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('View Details', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 28)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int score;

  const _ScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final frac = score / 100.0;
    final barColor = score >= 70
        ? Colors.teal
        : score >= 50
            ? Colors.orange
            : Colors.red;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: frac,
        minHeight: 6,
        backgroundColor: FimmsColors.outline,
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
      ),
    );
  }
}
