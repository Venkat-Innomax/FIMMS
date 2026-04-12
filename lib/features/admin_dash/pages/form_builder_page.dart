import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/form_schema_repository.dart';
import '../../../models/form_schema.dart';

class FormBuilderPage extends ConsumerStatefulWidget {
  const FormBuilderPage({super.key});

  @override
  ConsumerState<FormBuilderPage> createState() => _FormBuilderPageState();
}

class _FormBuilderPageState extends ConsumerState<FormBuilderPage> {
  String _schemaType = 'hostel';

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(formSchemaRepositoryProvider);

    return FutureBuilder<FormSchema>(
      future: _schemaType == 'hostel'
          ? repo.hostelSchema()
          : repo.hospitalSchema(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final schema = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'hostel', label: Text('Hostel')),
                      ButtonSegment(value: 'hospital', label: Text('Hospital')),
                    ],
                    selected: {_schemaType},
                    onSelectionChanged: (s) =>
                        setState(() => _schemaType = s.first),
                  ),
                  const Spacer(),
                  Text(
                    '${schema.sections.length} sections',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FimmsColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schema.sections.length,
                itemBuilder: (context, index) {
                  final section = schema.sections[index];
                  return _SectionCard(section: section, index: index);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final FormSection section;
  final int index;
  const _SectionCard({required this.section, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: FimmsColors.outline),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: FimmsColors.primary.withValues(alpha: 0.1),
          child: Text('${index + 1}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FimmsColors.primary)),
        ),
        title: Text(section.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          'Max score: ${section.maxScore} · ${section.fields.length} fields',
          style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final field in section.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: FimmsColors.primary.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(field.label,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FimmsColors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            field.type.name,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: FimmsColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('w: ${field.weight}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: FimmsColors.textMuted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
