import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/complaint.dart';
import '../../../models/facility.dart';
import 'facility_picker.dart';

class ComplaintForm extends ConsumerStatefulWidget {
  const ComplaintForm({super.key});

  @override
  ConsumerState<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends ConsumerState<ComplaintForm> {
  int _step = 0;
  Facility? _selectedFacility;
  ComplaintCategory? _selectedCategory;
  final _descController = TextEditingController();
  int _evidenceCount = 0;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              for (int i = 0; i < 4; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                        height: 2,
                        color: i <= _step
                            ? FimmsColors.primary
                            : FimmsColors.outline),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= _step
                        ? FimmsColors.primary
                        : FimmsColors.surface,
                    border: Border.all(
                      color: i <= _step
                          ? FimmsColors.primary
                          : FimmsColors.outline,
                    ),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i <= _step ? Colors.white : FimmsColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in ['Facility', 'Category', 'Details', 'Evidence'])
                Text(label,
                    style: const TextStyle(
                        fontSize: 9, color: FimmsColors.textMuted)),
            ],
          ),
          const SizedBox(height: 20),

          // Step content
          if (_step == 0) ...[
            const Text('Select Facility',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FacilityPicker(
              selectedId: _selectedFacility?.id,
              onSelected: (f) => setState(() => _selectedFacility = f),
            ),
          ],
          if (_step == 1) ...[
            const Text('Select Category',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in ComplaintCategory.values)
                  ChoiceChip(
                    label: Text(cat.label),
                    selected: _selectedCategory == cat,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                  ),
              ],
            ),
          ],
          if (_step == 2) ...[
            const Text('Describe the Issue',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText:
                    'Provide details about the issue (minimum 20 characters)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 4),
            Text(
              '${_descController.text.length}/20 characters minimum',
              style: TextStyle(
                fontSize: 11,
                color: _descController.text.length >= 20
                    ? FimmsColors.success
                    : FimmsColors.textMuted,
              ),
            ),
          ],
          if (_step == 3) ...[
            const Text('Upload Evidence',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FimmsColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FimmsColors.outline),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload,
                      size: 40, color: FimmsColors.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    _evidenceCount > 0
                        ? '$_evidenceCount file(s) attached'
                        : 'No files attached (optional)',
                    style: const TextStyle(color: FimmsColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _evidenceCount++),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _evidenceCount++),
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('File'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                ),
              const Spacer(),
              if (_step < 3)
                FilledButton(
                  onPressed: _canAdvance()
                      ? () => setState(() => _step++)
                      : null,
                  child: const Text('Next'),
                ),
              if (_step == 3)
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Complaint submitted (demo mode)')),
                    );
                    setState(() {
                      _step = 0;
                      _selectedFacility = null;
                      _selectedCategory = null;
                      _descController.clear();
                      _evidenceCount = 0;
                    });
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Submit Complaint'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canAdvance() {
    switch (_step) {
      case 0:
        return _selectedFacility != null;
      case 1:
        return _selectedCategory != null;
      case 2:
        return _descController.text.length >= 20;
      default:
        return true;
    }
  }
}
