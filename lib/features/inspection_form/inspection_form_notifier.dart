import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/form_schema.dart';
import '../../services/scoring_engine.dart';

class InspectionFormState {
  final Responses responses; // keyed by "{sectionId}.{fieldId}"
  final Map<String, String> remarksBySection;
  final Map<String, List<String>> photosBySection;
  final Set<String> skippedSections;
  final bool urgentFlag;
  final String? urgentReason;

  const InspectionFormState({
    required this.responses,
    required this.remarksBySection,
    required this.photosBySection,
    required this.skippedSections,
    required this.urgentFlag,
    required this.urgentReason,
  });

  factory InspectionFormState.empty() => const InspectionFormState(
        responses: {},
        remarksBySection: {},
        photosBySection: {},
        skippedSections: {},
        urgentFlag: false,
        urgentReason: null,
      );

  InspectionFormState copyWith({
    Responses? responses,
    Map<String, String>? remarksBySection,
    Map<String, List<String>>? photosBySection,
    Set<String>? skippedSections,
    bool? urgentFlag,
    String? urgentReason,
    bool clearUrgentReason = false,
  }) {
    return InspectionFormState(
      responses: responses ?? this.responses,
      remarksBySection: remarksBySection ?? this.remarksBySection,
      photosBySection: photosBySection ?? this.photosBySection,
      skippedSections: skippedSections ?? this.skippedSections,
      urgentFlag: urgentFlag ?? this.urgentFlag,
      urgentReason:
          clearUrgentReason ? null : (urgentReason ?? this.urgentReason),
    );
  }
}

class InspectionFormNotifier extends StateNotifier<InspectionFormState> {
  final FormSchema schema;

  InspectionFormNotifier({required this.schema})
      : super(InspectionFormState.empty());

  void setResponse(String sectionId, String fieldId, dynamic value) {
    final next = {...state.responses, '$sectionId.$fieldId': value};
    state = state.copyWith(responses: next);

    // Handle skip triggers.
    final section = schema.sections.firstWhere((s) => s.id == sectionId,
        orElse: () => FormSection(
              id: '',
              title: '',
              maxScore: 0,
              fields: const [],
            ));
    if (section.id.isNotEmpty &&
        section.skipTriggerField == fieldId &&
        section.skipTriggerValue != null) {
      final next = {...state.skippedSections};
      if (value == section.skipTriggerValue) {
        next.add(sectionId);
      } else {
        next.remove(sectionId);
      }
      state = state.copyWith(skippedSections: next);
    }
  }

  void setRemarks(String sectionId, String remarks) {
    final next = {...state.remarksBySection, sectionId: remarks};
    state = state.copyWith(remarksBySection: next);
  }

  void addPhoto(String sectionId, String path) {
    final current = List<String>.from(
      state.photosBySection[sectionId] ?? const [],
    )..add(path);
    final next = {...state.photosBySection, sectionId: current};
    state = state.copyWith(photosBySection: next);
  }

  void removePhoto(String sectionId, int idx) {
    final current = List<String>.from(
      state.photosBySection[sectionId] ?? const [],
    );
    if (idx < 0 || idx >= current.length) return;
    current.removeAt(idx);
    final next = {...state.photosBySection, sectionId: current};
    state = state.copyWith(photosBySection: next);
  }

  void setUrgent({required bool flag, String? reason}) {
    state = state.copyWith(
      urgentFlag: flag,
      urgentReason: flag ? reason : null,
      clearUrgentReason: !flag,
    );
  }
}

final inspectionFormProvider = StateNotifierProvider.autoDispose
    .family<InspectionFormNotifier, InspectionFormState, FormSchema>(
  (ref, schema) => InspectionFormNotifier(schema: schema),
);
