/// Field type catalogue (spec §4.3, §4.4).
enum FieldType {
  yesNo,
  yesNoNa,
  goodAvgPoor,
  availPartialNa,
  regularInterruptedNa,
  number,
  text,
  dropdown,
  staffTable,
}

extension FieldTypeX on FieldType {
  static FieldType fromString(String value) {
    switch (value) {
      case 'yes_no':
        return FieldType.yesNo;
      case 'yes_no_na':
        return FieldType.yesNoNa;
      case 'good_avg_poor':
        return FieldType.goodAvgPoor;
      case 'avail_partial_na':
        return FieldType.availPartialNa;
      case 'regular_interrupted_na':
        return FieldType.regularInterruptedNa;
      case 'number':
        return FieldType.number;
      case 'text':
        return FieldType.text;
      case 'dropdown':
        return FieldType.dropdown;
      case 'staff_table':
        return FieldType.staffTable;
      default:
        throw ArgumentError('Unknown field type: $value');
    }
  }
}

class FormField {
  final String id;
  final String label;
  final FieldType type;
  final bool scored;
  final double weight; // contribution to section max when scored
  final List<String>? options; // for dropdown
  final List<String>? showFor; // sub-type codes this field is visible for
  final List<String>? hideFor;
  final List<StaffRole>? staffRoles; // for staff_table
  final bool dynamicRows; // staff_table: allow "add other staff"
  final String? helper;

  const FormField({
    required this.id,
    required this.label,
    required this.type,
    this.scored = false,
    this.weight = 0,
    this.options,
    this.showFor,
    this.hideFor,
    this.staffRoles,
    this.dynamicRows = false,
    this.helper,
  });

  bool isVisibleFor(String subType) {
    if (hideFor != null && hideFor!.contains(subType)) return false;
    if (showFor != null && showFor!.isNotEmpty) {
      return showFor!.contains(subType);
    }
    return true;
  }

  factory FormField.fromJson(Map<String, dynamic> json) => FormField(
        id: json['id'] as String,
        label: json['label'] as String,
        type: FieldTypeX.fromString(json['type'] as String),
        scored: json['scored'] as bool? ?? false,
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        options: (json['options'] as List?)?.cast<String>(),
        showFor: (json['show_for'] as List?)?.cast<String>(),
        hideFor: (json['hide_for'] as List?)?.cast<String>(),
        staffRoles: (json['staff_roles'] as List?)
            ?.map((e) => StaffRole.fromJson(e as Map<String, dynamic>))
            .toList(),
        dynamicRows: json['dynamic_rows'] as bool? ?? false,
        helper: json['helper'] as String?,
      );
}

class StaffRole {
  final String id;
  final String label;

  const StaffRole({required this.id, required this.label});

  factory StaffRole.fromJson(Map<String, dynamic> json) => StaffRole(
        id: json['id'] as String,
        label: json['label'] as String,
      );
}

class FormSection {
  final String id;
  final String title;
  final double maxScore;
  final List<FormField> fields;
  final bool requiresRemarks;
  final bool requiresPhoto;
  final String? skipTriggerField; // field id that, if "no_mess", skips section
  final String? skipTriggerValue;
  final String? notes;

  const FormSection({
    required this.id,
    required this.title,
    required this.maxScore,
    required this.fields,
    this.requiresRemarks = true,
    this.requiresPhoto = true,
    this.skipTriggerField,
    this.skipTriggerValue,
    this.notes,
  });

  bool get canSkip => skipTriggerField != null;

  factory FormSection.fromJson(Map<String, dynamic> json) => FormSection(
        id: json['id'] as String,
        title: json['title'] as String,
        maxScore: (json['max_score'] as num).toDouble(),
        fields: ((json['fields'] as List?) ?? const [])
            .map((e) => FormField.fromJson(e as Map<String, dynamic>))
            .toList(),
        requiresRemarks: json['requires_remarks'] as bool? ?? true,
        requiresPhoto: json['requires_photo'] as bool? ?? true,
        skipTriggerField: json['skip_trigger_field'] as String?,
        skipTriggerValue: json['skip_trigger_value'] as String?,
        notes: json['notes'] as String?,
      );
}

class FormSchema {
  final String id; // 'hostel' or 'hospital'
  final String title;
  final List<FormSection> sections;

  const FormSchema({
    required this.id,
    required this.title,
    required this.sections,
  });

  double get totalMaxScore =>
      sections.fold(0, (sum, s) => sum + s.maxScore);

  factory FormSchema.fromJson(Map<String, dynamic> json) => FormSchema(
        id: json['id'] as String,
        title: json['title'] as String,
        sections: ((json['sections'] as List?) ?? const [])
            .map((e) => FormSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
