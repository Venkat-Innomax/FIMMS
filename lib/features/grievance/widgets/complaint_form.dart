import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/complaint.dart';
import '../../../models/facility.dart';
import 'facility_picker.dart';

// Complaint type chosen at the start of the form
enum _ComplaintType { student, citizen }

class ComplaintForm extends ConsumerStatefulWidget {
  const ComplaintForm({super.key});

  @override
  ConsumerState<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends ConsumerState<ComplaintForm> {
  // Step -1 = type selection, 0 = roll-number (student) or facility, etc.
  _ComplaintType? _complaintType;
  bool _rollVerified = false;
  final _rollCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _rollLoading = false;
  String? _verifiedStudent; // e.g. "Ravi Kumar, Class X, SW Hostel Bhongir"

  int _step = 0;
  Facility? _selectedFacility;
  ComplaintCategory? _selectedCategory;
  final _descController = TextEditingController();
  int _evidenceCount = 0;

  @override
  void dispose() {
    _descController.dispose();
    _rollCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyRoll() async {
    if (_rollCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) return;
    setState(() => _rollLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _rollLoading = false;
      _rollVerified = true;
      _verifiedStudent =
          '${_nameCtrl.text.trim()}, Class X — SW Boys Hostel, Bhongir';
    });
  }

  void _resetForm() {
    setState(() {
      _complaintType = null;
      _rollVerified = false;
      _verifiedStudent = null;
      _rollCtrl.clear();
      _nameCtrl.clear();
      _step = 0;
      _selectedFacility = null;
      _selectedCategory = null;
      _descController.clear();
      _evidenceCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Step -1: type selection
    if (_complaintType == null) {
      return _TypeSelectionView(
        onSelect: (t) => setState(() => _complaintType = t),
      );
    }

    // Roll number verification for students (before step 0)
    if (_complaintType == _ComplaintType.student && !_rollVerified) {
      return _RollVerificationView(
        rollCtrl: _rollCtrl,
        nameCtrl: _nameCtrl,
        loading: _rollLoading,
        verifiedStudent: _verifiedStudent,
        onVerify: _verifyRoll,
        onVerifiedContinue: () => setState(() {}),
        onBack: () => setState(() => _complaintType = null),
      );
    }

    final totalSteps = 4;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to type selection
          TextButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.arrow_back, size: 14),
            label: Text(
              _complaintType == _ComplaintType.student
                  ? 'Student Complaint'
                  : 'Citizen Complaint',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
          ),
          if (_verifiedStudent != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: FimmsColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: FimmsColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user,
                      size: 14, color: FimmsColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _verifiedStudent!,
                      style: const TextStyle(
                          fontSize: 11, color: FimmsColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Progress indicator
          Row(
            children: [
              for (int i = 0; i < totalSteps; i++) ...[
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Facility', style: TextStyle(fontSize: 9, color: FimmsColors.textMuted)),
              Text('Category', style: TextStyle(fontSize: 9, color: FimmsColors.textMuted)),
              Text('Details', style: TextStyle(fontSize: 9, color: FimmsColors.textMuted)),
              Text('Evidence', style: TextStyle(fontSize: 9, color: FimmsColors.textMuted)),
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
              if (_step < totalSteps - 1)
                FilledButton(
                  onPressed: _canAdvance()
                      ? () => setState(() => _step++)
                      : null,
                  child: const Text('Next'),
                ),
              if (_step == totalSteps - 1)
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Complaint submitted (demo mode)')),
                    );
                    _resetForm();
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

// ---------------------------------------------------------------------------
// Type selection view
// ---------------------------------------------------------------------------

class _TypeSelectionView extends StatelessWidget {
  final ValueChanged<_ComplaintType> onSelect;
  const _TypeSelectionView({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('File a Complaint',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Select the type of complaint you want to file.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: FimmsColors.textMuted)),
          const SizedBox(height: 28),
          _TypeCard(
            icon: Icons.school_outlined,
            title: 'Student / Hostel Complaint',
            description:
                'For students filing complaints about hostel facilities, food, safety, or services.',
            color: FimmsColors.primary,
            onTap: () => onSelect(_ComplaintType.student),
          ),
          const SizedBox(height: 14),
          _TypeCard(
            icon: Icons.people_outline,
            title: 'Citizen / Hospital Complaint',
            description:
                'For citizens filing complaints about hospital or healthcare facility services.',
            color: Colors.teal,
            onTap: () => onSelect(_ComplaintType.citizen),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FimmsColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 12,
                            color: FimmsColors.textMuted,
                            height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Roll number verification view (Student)
// ---------------------------------------------------------------------------

class _RollVerificationView extends StatelessWidget {
  final TextEditingController rollCtrl;
  final TextEditingController nameCtrl;
  final bool loading;
  final String? verifiedStudent;
  final VoidCallback onVerify;
  final VoidCallback onVerifiedContinue;
  final VoidCallback onBack;

  const _RollVerificationView({
    required this.rollCtrl,
    required this.nameCtrl,
    required this.loading,
    required this.verifiedStudent,
    required this.onVerify,
    required this.onVerifiedContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('Back', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
          ),
          const SizedBox(height: 12),
          Text('Student Verification',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Please verify your identity using your roll number before filing a complaint.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: FimmsColors.textMuted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: rollCtrl,
            decoration: const InputDecoration(
              labelText: 'Roll Number',
              hintText: 'e.g. 2024SW0123',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Student Name',
              hintText: 'As per admission records',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (verifiedStudent == null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading ? null : onVerify,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_outlined),
                label: Text(loading ? 'Verifying...' : 'Verify Identity'),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FimmsColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: FimmsColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: FimmsColors.success, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Identity Verified',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FimmsColors.success)),
                        const SizedBox(height: 2),
                        Text(verifiedStudent!,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onVerifiedContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Complaint Form'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FimmsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FimmsColors.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: FimmsColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your identity will be kept confidential. Only authorized officers can view your name.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: FimmsColors.textMuted),
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
