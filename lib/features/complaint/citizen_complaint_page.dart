import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';

class CitizenComplaintPage extends ConsumerStatefulWidget {
  const CitizenComplaintPage({super.key});

  @override
  ConsumerState<CitizenComplaintPage> createState() =>
      _CitizenComplaintPageState();
}

class _CitizenComplaintPageState extends ConsumerState<CitizenComplaintPage> {
  int _step = 0; // 0=Facility, 1=Identity, 2=Complaint, 3=Submitted

  // Step 0
  String? _selectedFacility;

  // Step 1
  final _nameCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  String? _maskedIdentity;

  // Step 2
  String? _category;
  final _complaintCtrl = TextEditingController();

  // Step 3
  String? _trackingId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aadhaarCtrl.dispose();
    _complaintCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Complaint — Citizen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _FacilityStep(
          key: const ValueKey(0),
          selected: _selectedFacility,
          onSelect: (f) => setState(() => _selectedFacility = f),
          onNext: () => setState(() => _step = 1),
        ),
      1 => _IdentityStep(
          key: const ValueKey(1),
          nameController: _nameCtrl,
          aadhaarController: _aadhaarCtrl,
          onNext: _processIdentity,
          onBack: () => setState(() => _step = 0),
        ),
      2 => _ComplaintFormStep(
          key: const ValueKey(2),
          facility: _selectedFacility!,
          maskedIdentity: _maskedIdentity!,
          category: _category,
          controller: _complaintCtrl,
          onCategorySelect: (c) => setState(() => _category = c),
          onSubmit: _submit,
          onBack: () => setState(() => _step = 1),
        ),
      _ => _SubmittedStep(
          key: const ValueKey(3),
          trackingId: _trackingId ?? 'HSP-2026-0001',
          onNew: () => setState(() {
            _step = 0;
            _selectedFacility = null;
            _maskedIdentity = null;
            _category = null;
            _complaintCtrl.clear();
            _nameCtrl.clear();
            _aadhaarCtrl.clear();
          }),
        ),
    };
  }

  void _processIdentity() {
    final name = _nameCtrl.text.trim();
    final aadhaar = _aadhaarCtrl.text.trim().replaceAll(' ', '');
    if (name.isEmpty || aadhaar.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name and last 4 digits of Aadhaar')));
      return;
    }
    // Mask the name: keep first letter, replace rest with *
    final masked = '${name[0]}${'*' * (name.length > 1 ? name.length - 1 : 2)}';
    final maskedId = 'XXXX-XXXX-${aadhaar.substring(aadhaar.length - 4)}';
    setState(() {
      _maskedIdentity = '$masked • $maskedId';
      _step = 2;
    });
  }

  void _submit() {
    if (_category == null || _complaintCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category and describe the issue')));
      return;
    }
    setState(() {
      _trackingId = 'HSP-2026-${(1000 + DateTime.now().millisecond % 999)}';
      _step = 3;
    });
  }
}

// ---------------------------------------------------------------------------
// Step 0 — Facility Selection
// ---------------------------------------------------------------------------

class _FacilityStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  const _FacilityStep({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  static const _hospitals = [
    ('District Hospital — Bhongir', 'District Hospital', Icons.local_hospital),
    ('CHC — Bhongir', 'Community Health Centre', Icons.medical_services),
    ('CHC — Choutuppal', 'Community Health Centre', Icons.medical_services),
    ('CHC — Ramannapet', 'Community Health Centre', Icons.medical_services),
    ('PHC — Yadagirigutta', 'Primary Health Centre', Icons.health_and_safety),
    ('PHC — Motakondur', 'Primary Health Centre', Icons.health_and_safety),
    ('PHC — Mothkur', 'Primary Health Centre', Icons.health_and_safety),
    ('PHC — Pochampally', 'Primary Health Centre', Icons.health_and_safety),
    ('PHC — Bommalaramaram', 'Primary Health Centre', Icons.health_and_safety),
    ('UPHC — Bhuvanagiri', 'Urban PHC', Icons.location_city),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 1, total: 3),
        const SizedBox(height: 20),
        const Text('Select Health Facility',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          'Choose the hospital or health centre where you experienced the issue.',
          style: TextStyle(fontSize: 12, color: FimmsColors.textMuted),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _hospitals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final (name, type, icon) = _hospitals[i];
              final isSelected = selected == name;
              return ListTile(
                tileColor: isSelected
                    ? Colors.teal.withValues(alpha: 0.07)
                    : Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: isSelected ? Colors.teal : FimmsColors.outline,
                      width: isSelected ? 1.5 : 1),
                ),
                leading: Icon(icon,
                    color: isSelected ? Colors.teal : FimmsColors.textMuted),
                title: Text(name, style: const TextStyle(fontSize: 13)),
                subtitle: Text(type, style: const TextStyle(fontSize: 11)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.teal)
                    : null,
                onTap: () => onSelect(name),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: selected == null ? null : onNext,
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Identity Input
// ---------------------------------------------------------------------------

class _IdentityStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController aadhaarController;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _IdentityStep({
    super.key,
    required this.nameController,
    required this.aadhaarController,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 2, total: 3),
        const SizedBox(height: 20),
        const Text('Your Identity (Private)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FimmsColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: FimmsColors.primary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your identity will be masked in all reports. Only authorized officers can access identity details.',
                  style: TextStyle(fontSize: 11, color: FimmsColors.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: aadhaarController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'Last 4 digits of Aadhaar',
            hintText: 'e.g. 5678',
            prefixIcon: Icon(Icons.credit_card_outlined),
            border: OutlineInputBorder(),
            helperText: 'Only last 4 digits — stored as XXXX-XXXX-XXXX',
          ),
        ),
        const Spacer(),
        Row(
          children: [
            OutlinedButton(onPressed: onBack, child: const Text('Back')),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Complaint Form
// ---------------------------------------------------------------------------

class _ComplaintFormStep extends StatelessWidget {
  final String facility;
  final String maskedIdentity;
  final String? category;
  final TextEditingController controller;
  final ValueChanged<String> onCategorySelect;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ComplaintFormStep({
    super.key,
    required this.facility,
    required this.maskedIdentity,
    required this.category,
    required this.controller,
    required this.onCategorySelect,
    required this.onSubmit,
    required this.onBack,
  });

  static const _categories = [
    'Cleanliness',
    'Medicines Unavailable',
    'Staff Behaviour',
    'Infrastructure',
    'Service Denial',
    'Waiting Time',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _StepIndicator(current: 3, total: 3),
        const SizedBox(height: 16),
        Text('Facility: $facility',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        Text('Identity: $maskedIdentity',
            style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
        const SizedBox(height: 16),
        const Text('Complaint Category',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FimmsColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final sel = category == c;
            return FilterChip(
              label: Text(c),
              selected: sel,
              selectedColor: Colors.teal.withValues(alpha: 0.15),
              checkmarkColor: Colors.teal,
              onSelected: (_) => onCategorySelect(c),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Describe the issue',
            hintText: 'What happened? When? Any other details...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.attach_file, color: FimmsColors.textMuted, size: 18),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo upload — not wired in demo'))),
              child: const Text('Attach Evidence (optional)'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton(onPressed: onBack, child: const Text('Back')),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Submit Complaint'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Submitted
// ---------------------------------------------------------------------------

class _SubmittedStep extends StatelessWidget {
  final String trackingId;
  final VoidCallback onNew;

  const _SubmittedStep({super.key, required this.trackingId, required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 72, color: Colors.teal),
          const SizedBox(height: 16),
          const Text('Complaint Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Your complaint has been recorded. The concerned health officer will review it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FimmsColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text('Tracking ID',
                    style: TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
                const SizedBox(height: 4),
                Text(trackingId,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.teal)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.refresh),
            label: const Text('File Another Complaint'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Indicator (shared)
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= total; i++) ...[
          CircleAvatar(
            radius: 12,
            backgroundColor:
                i <= current ? Colors.teal : FimmsColors.outline,
            child: Text('$i',
                style: TextStyle(
                    fontSize: 11,
                    color: i <= current ? Colors.white : FimmsColors.textMuted,
                    fontWeight: FontWeight.w700)),
          ),
          if (i < total) ...[
            Expanded(
              child: Container(
                height: 2,
                color: i < current ? Colors.teal : FimmsColors.outline,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
