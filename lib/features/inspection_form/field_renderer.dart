import 'package:flutter/material.dart' hide FormField;
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/form_schema.dart';
import 'widgets/choice_chip_row.dart';
import 'widgets/staff_table.dart';

/// Dispatches on [FormField.type] and renders the appropriate input widget.
/// Each widget calls back with the response value in the shape expected by
/// the scoring engine.
class FieldRenderer extends StatelessWidget {
  final FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const FieldRenderer({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: FimmsColors.textPrimary,
          ),
        ),
        if (field.helper != null) ...[
          const SizedBox(height: 2),
          Text(
            field.helper!,
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: FimmsColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildInput(),
      ],
    );
  }

  Widget _buildInput() {
    switch (field.type) {
      case FieldType.yesNo:
        return ChoiceChipRow(
          value: value as String?,
          onChanged: onChanged,
          options: const [
            ChoiceOption(value: 'yes', label: 'Yes'),
            ChoiceOption(value: 'no', label: 'No'),
          ],
        );

      case FieldType.yesNoNa:
        return ChoiceChipRow(
          value: value as String?,
          onChanged: onChanged,
          options: const [
            ChoiceOption(value: 'yes', label: 'Yes'),
            ChoiceOption(value: 'no', label: 'No'),
            ChoiceOption(value: 'na', label: 'Not Applicable'),
          ],
        );

      case FieldType.goodAvgPoor:
        return ChoiceChipRow(
          value: value as String?,
          onChanged: onChanged,
          options: const [
            ChoiceOption(
                value: 'good', label: 'Good', accent: FimmsColors.gradeExcellent),
            ChoiceOption(
                value: 'average', label: 'Average', accent: FimmsColors.gradeAverage),
            ChoiceOption(
                value: 'poor', label: 'Poor', accent: FimmsColors.gradeCritical),
          ],
        );

      case FieldType.availPartialNa:
        return ChoiceChipRow(
          value: value as String?,
          onChanged: onChanged,
          options: const [
            ChoiceOption(
                value: 'available',
                label: 'Available',
                accent: FimmsColors.gradeExcellent),
            ChoiceOption(
                value: 'partial',
                label: 'Partial',
                accent: FimmsColors.gradeAverage),
            ChoiceOption(
                value: 'not_available',
                label: 'Not Available',
                accent: FimmsColors.gradeCritical),
          ],
        );

      case FieldType.regularInterruptedNa:
        return ChoiceChipRow(
          value: value as String?,
          onChanged: onChanged,
          options: const [
            ChoiceOption(
                value: 'regular',
                label: 'Regular',
                accent: FimmsColors.gradeExcellent),
            ChoiceOption(
                value: 'interrupted',
                label: 'Interrupted',
                accent: FimmsColors.gradeAverage),
            ChoiceOption(
                value: 'not_available',
                label: 'Not Available',
                accent: FimmsColors.gradeCritical),
          ],
        );

      case FieldType.number:
        return SizedBox(
          width: 180,
          child: TextFormField(
            initialValue: value?.toString() ?? '',
            decoration: const InputDecoration(hintText: '0'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => onChanged(int.tryParse(v)),
          ),
        );

      case FieldType.text:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          maxLines: 2,
          onChanged: onChanged,
        );

      case FieldType.date:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            hintText: 'DD/MM/YYYY',
            prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
          ),
          onChanged: onChanged,
        );

      case FieldType.time:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            hintText: 'HH:MM',
            prefixIcon: Icon(Icons.access_time_outlined, size: 18),
          ),
          onChanged: onChanged,
        );

      case FieldType.dropdown:
        return DropdownButtonFormField<String>(
          initialValue: value as String?,
          items: [
            for (final opt in field.options ?? const <String>[])
              DropdownMenuItem(value: opt, child: Text(opt)),
          ],
          onChanged: (v) => onChanged(v),
        );

      case FieldType.staffTable:
        final rows = (value is List)
            ? List<Map<String, dynamic>>.from(value as List)
            : const <Map<String, dynamic>>[];
        return StaffTable(
          roles: field.staffRoles ?? const [],
          allowAdditionalRows: field.dynamicRows,
          value: rows,
          onChanged: onChanged,
        );
    }
  }
}

