import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/form_schema.dart';
import '../../services/photo_capture_service.dart';
import 'inspection_form_notifier.dart';

/// Shared footer for each section: remarks text field + photo row.
class SectionFooter extends ConsumerWidget {
  final FormSchema schema;
  final FormSection section;

  const SectionFooter({
    super.key,
    required this.schema,
    required this.section,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionFormProvider(schema));
    final notifier = ref.read(inspectionFormProvider(schema).notifier);

    final remarks = state.remarksBySection[section.id] ?? '';
    final photos = state.photosBySection[section.id] ?? const [];
    final remarksTooShort =
        remarks.trim().length < AppConstants.minRemarksChars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notes, size: 16, color: FimmsColors.textMuted),
            const SizedBox(width: 8),
            Text(
              'Remarks${section.requiresRemarks ? " *" : ""}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FimmsColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              '${remarks.length} / ${AppConstants.minRemarksChars} min',
              style: TextStyle(
                fontSize: 10.5,
                color: remarksTooShort
                    ? FimmsColors.gradeCritical
                    : FimmsColors.gradeExcellent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('remarks_${section.id}'),
          initialValue: remarks,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Describe conditions observed in this section…',
          ),
          onChanged: (v) => notifier.setRemarks(section.id, v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.photo_camera_outlined,
                size: 16, color: FimmsColors.textMuted),
            const SizedBox(width: 8),
            Text(
              'Photo evidence${section.requiresPhoto ? " *" : ""}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FimmsColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              '${photos.length} captured',
              style: TextStyle(
                fontSize: 11,
                color: photos.isEmpty
                    ? FimmsColors.gradeCritical
                    : FimmsColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PhotoRow(
          photos: photos,
          onAdd: () async {
            final path = await ref
                .read(photoCaptureServiceProvider)
                .capture();
            if (path != null) notifier.addPhoto(section.id, path);
          },
          onRemove: (i) => notifier.removePhoto(section.id, i),
        ),
      ],
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoRow({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddTile(onTap: onAdd),
          for (var i = 0; i < photos.length; i++) ...[
            const SizedBox(width: 8),
            _PhotoTile(
              path: photos[i],
              onRemove: () => onRemove(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: FimmsColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: FimmsColors.outline,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 22, color: FimmsColors.textMuted),
            SizedBox(height: 4),
            Text(
              'Capture',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: FimmsColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _PhotoTile({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (path.startsWith('sample:')) {
      image = Container(
        color: FimmsColors.primary.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined,
                size: 22, color: FimmsColors.primary),
            SizedBox(height: 2),
            Text(
              'SAMPLE',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: FimmsColors.primary,
              ),
            ),
          ],
        ),
      );
    } else if (!kIsWeb && File(path).existsSync()) {
      image = Image.file(File(path), fit: BoxFit.cover);
    } else {
      image = Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
        return Container(color: FimmsColors.surface);
      });
    }

    return Stack(
      children: [
        Container(
          width: 84,
          height: 84,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FimmsColors.outline),
          ),
          child: image,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
