import 'package:flutter/material.dart';

import '../../core/theme.dart';

class _DemoNotification {
  final String title;
  final String body;
  final String time;
  const _DemoNotification(
      {required this.title, required this.body, required this.time});
}

const _demoNotifications = [
  _DemoNotification(
    title: 'New Assignment',
    body: 'You have been assigned to inspect SW Boys Hostel, Bhongir',
    time: '2 hours ago',
  ),
  _DemoNotification(
    title: 'Re-inspection Order',
    body: 'Re-inspection ordered for PHC Mothkur — medicines stockout',
    time: '1 day ago',
  ),
  _DemoNotification(
    title: 'Inspection Approved',
    body: 'Your inspection of CHC Alair has been approved',
    time: '2 days ago',
  ),
];

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(context),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: FimmsColors.danger,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '3',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('Notifications',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Spacer(),
                  Text('3 new',
                      style: TextStyle(
                          fontSize: 12,
                          color: FimmsColors.danger,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Divider(),
            for (final n in _demoNotifications)
              ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      FimmsColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.notifications,
                      size: 18, color: FimmsColors.primary),
                ),
                title: Text(n.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(n.body,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: Text(n.time,
                    style: const TextStyle(
                        fontSize: 10, color: FimmsColors.textMuted)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
