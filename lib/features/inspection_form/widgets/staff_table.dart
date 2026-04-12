import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../models/form_schema.dart';

/// Renders the Staff & Availability table (spec §4.3 Section 4 /
/// §4.4 Section 2). Officer types sanctioned + present; we auto-compute
/// Less / Equal / More and display a badge.
class StaffTable extends StatefulWidget {
  final List<StaffRole> roles;
  final bool allowAdditionalRows;
  final List<Map<String, dynamic>> value;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const StaffTable({
    super.key,
    required this.roles,
    required this.allowAdditionalRows,
    required this.value,
    required this.onChanged,
  });

  @override
  State<StaffTable> createState() => _StaffTableState();
}

class _StaffTableState extends State<StaffTable> {
  late List<_Row> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _buildInitialRows();
  }

  List<_Row> _buildInitialRows() {
    final byId = {for (final v in widget.value) v['role_id']: v};
    final rows = <_Row>[];
    for (final role in widget.roles) {
      final existing = byId[role.id] as Map<String, dynamic>?;
      rows.add(_Row(
        roleId: role.id,
        label: role.label,
        sanctioned: (existing?['sanctioned'] as num?)?.toInt() ?? 0,
        present: (existing?['present'] as num?)?.toInt() ?? 0,
        custom: false,
      ));
    }
    // Any extra custom rows from prior state.
    for (final v in widget.value) {
      if (!widget.roles.any((r) => r.id == v['role_id'])) {
        rows.add(_Row(
          roleId: v['role_id'] as String,
          label: v['label'] as String? ?? 'Other',
          sanctioned: (v['sanctioned'] as num?)?.toInt() ?? 0,
          present: (v['present'] as num?)?.toInt() ?? 0,
          custom: true,
        ));
      }
    }
    return rows;
  }

  void _emit() {
    widget.onChanged(_rows
        .map((r) => {
              'role_id': r.roleId,
              'label': r.label,
              'sanctioned': r.sanctioned,
              'present': r.present,
            })
        .toList());
  }

  void _addCustom() {
    setState(() {
      _rows.add(_Row(
        roleId: 'custom_${_rows.length}',
        label: 'Other staff',
        sanctioned: 0,
        present: 0,
        custom: true,
      ));
    });
    _emit();
  }

  void _removeRow(int idx) {
    setState(() => _rows.removeAt(idx));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
          child: Row(
            children: const [
              Expanded(
                flex: 4,
                child: Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  'Sanc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  'Pres.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 88,
                child: Text(
                  'Status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < _rows.length; i++)
          _StaffRowWidget(
            row: _rows[i],
            onChanged: (row) {
              setState(() => _rows[i] = row);
              _emit();
            },
            onDelete: _rows[i].custom ? () => _removeRow(i) : null,
          ),
        if (widget.allowAdditionalRows)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addCustom,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add other staff'),
            ),
          ),
      ],
    );
  }
}

class _Row {
  final String roleId;
  final String label;
  final int sanctioned;
  final int present;
  final bool custom;
  const _Row({
    required this.roleId,
    required this.label,
    required this.sanctioned,
    required this.present,
    required this.custom,
  });

  _Row copyWith({String? label, int? sanctioned, int? present}) => _Row(
        roleId: roleId,
        label: label ?? this.label,
        sanctioned: sanctioned ?? this.sanctioned,
        present: present ?? this.present,
        custom: custom,
      );

  _Status get status {
    if (sanctioned == 0) return _Status.pending;
    if (present >= sanctioned) return _Status.meetsOrMore;
    final ratio = present / sanctioned;
    if (ratio >= 0.75) return _Status.partial;
    return _Status.less;
  }
}

enum _Status { pending, meetsOrMore, partial, less }

class _StaffRowWidget extends StatelessWidget {
  final _Row row;
  final ValueChanged<_Row> onChanged;
  final VoidCallback? onDelete;

  const _StaffRowWidget({
    required this.row,
    required this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = row.status;
    Color statusColor;
    String statusLabel;
    switch (status) {
      case _Status.pending:
        statusColor = FimmsColors.textMuted;
        statusLabel = '—';
        break;
      case _Status.meetsOrMore:
        statusColor = FimmsColors.gradeExcellent;
        statusLabel = 'Equal/More';
        break;
      case _Status.partial:
        statusColor = FimmsColors.gradeAverage;
        statusLabel = '≥75%';
        break;
      case _Status.less:
        statusColor = FimmsColors.gradeCritical;
        statusLabel = '<75%';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FimmsColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FimmsColors.outline),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: row.custom
                  ? TextFormField(
                      initialValue: row.label,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Staff role',
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (v) => onChanged(row.copyWith(label: v)),
                    )
                  : Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            SizedBox(
              width: 72,
              child: _NumberBox(
                value: row.sanctioned,
                onChanged: (v) => onChanged(row.copyWith(sanctioned: v)),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: _NumberBox(
                value: row.present,
                onChanged: (v) => onChanged(row.copyWith(present: v)),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 88,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Remove row',
                iconSize: 16,
                padding: const EdgeInsets.only(left: 4),
                constraints: const BoxConstraints(),
                onPressed: onDelete,
                icon: const Icon(Icons.close,
                    size: 16, color: FimmsColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumberBox extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _NumberBox({required this.value, required this.onChanged});

  @override
  State<_NumberBox> createState() => _NumberBoxState();
}

class _NumberBoxState extends State<_NumberBox> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value == 0 ? '' : widget.value.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _NumberBox old) {
    super.didUpdateWidget(old);
    if (widget.value != int.tryParse(_ctrl.text) && widget.value != 0) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        hintText: '0',
      ),
      onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
    );
  }
}
