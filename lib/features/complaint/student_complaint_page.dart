import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';

class StudentComplaintPage extends ConsumerStatefulWidget {
  const StudentComplaintPage({super.key});

  @override
  ConsumerState<StudentComplaintPage> createState() =>
      _StudentComplaintPageState();
}

class _StudentComplaintPageState extends ConsumerState<StudentComplaintPage> {
  int _step = 0; // 0=Roll No, 1=Hostel, 2=Complaint, 3=Submitted

  // Step 0 state
  final _rollCtrl = TextEditingController();
  bool _verifying = false;
  String? _verifiedName;
  String? _rollError;

  // Step 1 state
  String? _selectedHostel;

  // Step 2 state
  String? _category;
  final _complaintCtrl = TextEditingController();

  // Step 3 state
  String? _trackingId;

  @override
  void dispose() {
    _rollCtrl.dispose();
    _complaintCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Complaint — Student'),
        actions: [
          if (_step < 3)
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
      0 => _RollNumberStep(
          key: const ValueKey(0),
          controller: _rollCtrl,
          verifying: _verifying,
          error: _rollError,
          onVerify: _verifyRollNumber,
        ),
      1 => _HostelSelectionStep(
          key: const ValueKey(1),
          verifiedName: _verifiedName!,
          rollNo: _rollCtrl.text.trim(),
          selected: _selectedHostel,
          onSelect: (h) => setState(() => _selectedHostel = h),
          onNext: () => setState(() => _step = 2),
          onBack: () => setState(() => _step = 0),
        ),
      2 => _ComplaintFormStep(
          key: const ValueKey(2),
          hostel: _selectedHostel!,
          category: _category,
          controller: _complaintCtrl,
          onCategorySelect: (c) => setState(() => _category = c),
          onSubmit: _submitComplaint,
          onBack: () => setState(() => _step = 1),
        ),
      _ => _SubmittedStep(
          key: const ValueKey(3),
          trackingId: _trackingId ?? 'CMP-2026-0001',
          onTrack: () => setState(() => _step = 0),
        ),
    };
  }

  Future<void> _verifyRollNumber() async {
    final roll = _rollCtrl.text.trim();
    if (roll.isEmpty) {
      setState(() => _rollError = 'Please enter your roll number');
      return;
    }
    setState(() { _verifying = true; _rollError = null; });
    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    // Mock: any non-empty roll number is valid
    setState(() {
      _verifying = false;
      _verifiedName = 'S*** Kumar'; // masked name
      _step = 1;
    });
  }

  void _submitComplaint() {
    if (_category == null || _complaintCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and enter complaint details')),
      );
      return;
    }
    setState(() {
      _trackingId = 'CMP-2026-${(1000 + DateTime.now().millisecond % 999)}';
      _step = 3;
    });
  }
}

// ---------------------------------------------------------------------------
// Step 0 — Roll Number Verification
// ---------------------------------------------------------------------------

class _RollNumberStep extends StatelessWidget {
  final TextEditingController controller;
  final bool verifying;
  final String? error;
  final VoidCallback onVerify;

  const _RollNumberStep({
    super.key,
    required this.controller,
    required this.verifying,
    required this.error,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 1, total: 3),
        const SizedBox(height: 24),
        const Text('Enter Your Roll Number',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'Your roll number will be used to verify your identity. '
          'Your name will be displayed in masked form for privacy.',
          style: TextStyle(fontSize: 13, color: FimmsColors.textMuted),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Roll Number',
            hintText: 'e.g. TS/BC/2024/12345',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: const OutlineInputBorder(),
            errorText: error,
          ),
          onSubmitted: (_) => onVerify(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: verifying ? null : onVerify,
            icon: verifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text(verifying ? 'Verifying...' : 'Verify Roll Number'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Hostel Selection
// ---------------------------------------------------------------------------

class _HostelSelectionStep extends StatelessWidget {
  final String verifiedName;
  final String rollNo;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _HostelSelectionStep({
    super.key,
    required this.verifiedName,
    required this.rollNo,
    required this.selected,
    required this.onSelect,
    required this.onNext,
    required this.onBack,
  });

  static const _hostels = [
    'Govt BC BH Mothkur',
    'KGBV Bhongir',
    'MJP Residential (BC) Boys School',
    'KGBV Addagudur',
    'TSWREIS (G) Addagudur',
    'Govt BC BH College Alair',
    'Govt ST Boys Hostel Alair',
    'TMREIS (Girls) Alair',
    'Govt BC BH Athmakur',
    'KGBV Athmakur (M)',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 2, total: 3),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.teal, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(verifiedName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('Roll No: $rollNo',
                      style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Select Your Hostel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _hostels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final hostel = _hostels[i];
              final isSelected = selected == hostel;
              return ListTile(
                tileColor: isSelected
                    ? FimmsColors.primary.withValues(alpha: 0.07)
                    : Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: isSelected ? FimmsColors.primary : FimmsColors.outline,
                      width: isSelected ? 1.5 : 1),
                ),
                leading: Icon(Icons.house,
                    color: isSelected ? FimmsColors.primary : FimmsColors.textMuted),
                title: Text(hostel, style: const TextStyle(fontSize: 13)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: FimmsColors.primary)
                    : null,
                onTap: () => onSelect(hostel),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton(onPressed: onBack, child: const Text('Back')),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: selected == null ? null : onNext,
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
  final String hostel;
  final String? category;
  final TextEditingController controller;
  final ValueChanged<String> onCategorySelect;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ComplaintFormStep({
    super.key,
    required this.hostel,
    required this.category,
    required this.controller,
    required this.onCategorySelect,
    required this.onSubmit,
    required this.onBack,
  });

  static const _categories = ['Food Quality', 'Facilities', 'Staff Behaviour', 'Safety', 'Sanitation', 'Other'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _StepIndicator(current: 3, total: 3),
        const SizedBox(height: 16),
        Text('Complaint for: $hostel',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text('Complaint Category',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FimmsColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final selected = category == c;
            return FilterChip(
              label: Text(c),
              selected: selected,
              onSelected: (_) => onCategorySelect(c),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Describe your complaint',
            hintText: 'Provide details about the issue...',
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
            Expanded(child: FilledButton(onPressed: onSubmit, child: const Text('Submit Complaint'))),
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
  final VoidCallback onTrack;

  const _SubmittedStep({super.key, required this.trackingId, required this.onTrack});

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
          const Text('Your complaint has been recorded and will be reviewed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FimmsColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: FimmsColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FimmsColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text('Tracking ID',
                    style: TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
                const SizedBox(height: 4),
                Text(trackingId,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: FimmsColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onTrack,
            icon: const Icon(Icons.refresh),
            label: const Text('File Another Complaint'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: Step indicator
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
                i <= current ? FimmsColors.primary : FimmsColors.outline,
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
                color: i < current ? FimmsColors.primary : FimmsColors.outline,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
