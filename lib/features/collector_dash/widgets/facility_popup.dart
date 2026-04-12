import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../../models/user.dart';
import '../../shared_widgets/grade_chip.dart';

/// Popup shown when a facility is tapped on the district map.
class FacilityPopup extends StatelessWidget {
  final Facility facility;
  final Inspection? inspection;
  final User? officer;
  final VoidCallback onClose;

  const FacilityPopup({
    super.key,
    required this.facility,
    required this.inspection,
    required this.officer,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FimmsColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FimmsColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: FimmsColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: FimmsColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    facility.type.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    facility.subTypeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: FimmsColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child:
                        Icon(Icons.close, size: 18, color: FimmsColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              facility.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${facility.village}, ${_mandalName(facility.mandalId)} Mandal',
              style: const TextStyle(
                fontSize: 12,
                color: FimmsColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            if (inspection != null) ...[
              Row(
                children: [
                  GradeChip(
                    grade: inspection!.grade,
                    scoreOutOf100: inspection!.totalScore,
                  ),
                  if (inspection!.urgentFlag) ...[
                    const SizedBox(width: 6),
                    const UrgentBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              _MetaRow(
                icon: Icons.person_outline,
                label: officer?.name ?? inspection!.officerId,
              ),
              _MetaRow(
                icon: Icons.calendar_today_outlined,
                label: dateFmt.format(inspection!.datetime),
              ),
              if (inspection!.urgentReason != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FimmsColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color:
                            FimmsColors.secondary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    inspection!.urgentReason!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: FimmsColors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ] else
              Text(
                'No inspection on record yet',
                style: TextStyle(
                  fontSize: 12,
                  color: FimmsColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.go('/collector/facility/${facility.id}');
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View detail'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _mandalName(String id) =>
      id.isEmpty ? '—' : (id[0].toUpperCase() + id.substring(1));
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: FimmsColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: FimmsColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
