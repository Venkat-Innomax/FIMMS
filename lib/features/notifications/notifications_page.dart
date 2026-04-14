import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';

// ---------------------------------------------------------------------------
// Mock notification data
// ---------------------------------------------------------------------------

enum _NotifType { assignment, inspection, complaint, escalation, system }

class _Notif {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final _NotifType type;
  bool read;

  _Notif({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.read = false,
  });
}

final _mockNotifications = <_Notif>[
  _Notif(
    id: 'n1',
    title: 'New Assignment',
    body: 'You have been assigned to inspect SW Boys Hostel, Bhongir',
    time: DateTime.now().subtract(const Duration(hours: 2)),
    type: _NotifType.assignment,
  ),
  _Notif(
    id: 'n2',
    title: 'Re-inspection Order',
    body: 'Re-inspection ordered for PHC Mothkur — medicines stockout flagged',
    time: DateTime.now().subtract(const Duration(hours: 6)),
    type: _NotifType.inspection,
  ),
  _Notif(
    id: 'n3',
    title: 'Inspection Approved',
    body: 'Your inspection of CHC Alair has been reviewed and approved',
    time: DateTime.now().subtract(const Duration(days: 1)),
    type: _NotifType.inspection,
    read: true,
  ),
  _Notif(
    id: 'n4',
    title: 'Complaint Escalated',
    body: 'Complaint GR-2024-041 has been escalated to District level',
    time: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
    type: _NotifType.escalation,
  ),
  _Notif(
    id: 'n5',
    title: 'Compliance Update',
    body: 'Welfare Officer submitted compliance proof for BC Girls Hostel, Ramannapeta',
    time: DateTime.now().subtract(const Duration(days: 2)),
    type: _NotifType.complaint,
    read: true,
  ),
  _Notif(
    id: 'n6',
    title: 'System Alert',
    body: '3 facilities have not been inspected in over 30 days — action required',
    time: DateTime.now().subtract(const Duration(days: 3)),
    type: _NotifType.system,
    read: true,
  ),
  _Notif(
    id: 'n7',
    title: 'New Assignment',
    body: 'PHC Mothkur added to your inspection queue for this week',
    time: DateTime.now().subtract(const Duration(days: 4)),
    type: _NotifType.assignment,
    read: true,
  ),
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _notifications = List<_Notif>.from(_mockNotifications);

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) _notifications[idx].read = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: FimmsColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 64),
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return _NotifTile(
                  notif: n,
                  onTap: () => _markRead(n.id),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile
// ---------------------------------------------------------------------------

class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  IconData get _icon => switch (notif.type) {
        _NotifType.assignment => Icons.assignment_outlined,
        _NotifType.inspection => Icons.fact_check_outlined,
        _NotifType.complaint => Icons.report_problem_outlined,
        _NotifType.escalation => Icons.north_east,
        _NotifType.system => Icons.info_outline,
      };

  Color get _color => switch (notif.type) {
        _NotifType.assignment => FimmsColors.primary,
        _NotifType.inspection => Colors.teal,
        _NotifType.complaint => FimmsColors.warning,
        _NotifType.escalation => FimmsColors.danger,
        _NotifType.system => FimmsColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(notif.time);
    return Material(
      color: notif.read ? Colors.transparent : FimmsColors.primary.withValues(alpha: 0.04),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(_icon, size: 20, color: _color),
                  ),
                  if (!notif.read)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: FimmsColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: notif.read
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: FimmsColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(
                              fontSize: 11, color: FimmsColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: notif.read
                            ? FimmsColors.textMuted
                            : FimmsColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('d MMM').format(dt);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 56, color: FimmsColors.textMuted),
          SizedBox(height: 16),
          Text('No notifications',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: FimmsColors.textMuted)),
          SizedBox(height: 4),
          Text("You're all caught up!",
              style: TextStyle(fontSize: 13, color: FimmsColors.textMuted)),
        ],
      ),
    );
  }
}
