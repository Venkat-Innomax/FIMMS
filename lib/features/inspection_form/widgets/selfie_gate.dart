import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../services/face_verification_service.dart';
import '../../../services/photo_capture_service.dart';
import '../../../services/profile_photo_provider.dart';

// ── Gate states ───────────────────────────────────────────────────────────

enum _GateState {
  idle,
  capturing,
  verifying,
  verified,
  failed,
  hardBlocked,
  webUnsupported,
  noProfilePhoto,
}

// ── SelfieGate ────────────────────────────────────────────────────────────

/// Displays a selfie-capture + face-verification step before the inspection
/// form body becomes accessible.
///
/// ## Lifecycle
/// 1. **Web** → immediately shows a hard-block message.
/// 2. **No profile photo** → "Please set your profile photo first."
/// 3. **Idle** → selfie camera button.
/// 4. **Verifying** → spinner.
/// 5. **Verified** → green success banner; calls [onVerified].
/// 6. **Failed (< maxAttempts)** → red warning + remaining retries.
/// 7. **Hard-blocked (maxAttempts exhausted)** → alert + permanent lock.
class SelfieGate extends ConsumerStatefulWidget {
  /// Called once when face verification succeeds. Use this to unlock the
  /// form body (e.g. `setState(() => _faceVerified = true)`).
  final VoidCallback onVerified;

  const SelfieGate({super.key, required this.onVerified});

  @override
  ConsumerState<SelfieGate> createState() => _SelfieGateState();
}

class _SelfieGateState extends ConsumerState<SelfieGate> {
  _GateState _state = _GateState.idle;
  int _attempts = 0;
  String? _selfiePath;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _state = _GateState.webUnsupported;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If already verified, show the compact success banner only.
    if (_state == _GateState.verified) return _VerifiedBanner();

    // Re-check profile photo state on every rebuild so if the user navigates
    // to Profile tab and sets a photo while inspection page is in the tree,
    // the gate updates.
    if (_state != _GateState.webUnsupported &&
        _state != _GateState.hardBlocked) {
      final profile = ref.watch(profilePhotoProvider);
      if (!profile.isSet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _state != _GateState.noProfilePhoto) {
            setState(() => _state = _GateState.noProfilePhoto);
          }
        });
      } else if (_state == _GateState.noProfilePhoto) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _state = _GateState.idle);
        });
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _borderColor,
          width: _state == _GateState.hardBlocked ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildBody(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _headerIconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_headerIcon, size: 20, color: _headerIconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identity Verification',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                _subtitle,
                style: const TextStyle(
                    fontSize: 11.5, color: FimmsColors.textMuted),
              ),
            ],
          ),
        ),
        if (_state != _GateState.webUnsupported)
          _AttemptBadge(attempts: _attempts),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    switch (_state) {
      case _GateState.webUnsupported:
        return _WebBlock();

      case _GateState.noProfilePhoto:
        return _NoProfileBlock();

      case _GateState.idle:
      case _GateState.failed:
        return _IdleBlock(
          onTap: _startCapture,
          failed: _state == _GateState.failed,
          attemptsRemaining: AppConstants.maxSelfieAttempts - _attempts,
          selfiePath: _selfiePath,
        );

      case _GateState.capturing:
        return _SpinnerBlock(label: 'Opening camera…');

      case _GateState.verifying:
        return _SpinnerBlock(label: 'Verifying identity…');

      case _GateState.hardBlocked:
        return _HardBlockedBlock();

      case _GateState.verified:
        return _VerifiedBanner(); // should not reach here (handled above)
    }
  }

  // ── Capture & verify flow ─────────────────────────────────────────────────

  Future<void> _startCapture() async {
    if (_state == _GateState.hardBlocked || _state == _GateState.verified) return;

    setState(() => _state = _GateState.capturing);

    // 1. Take selfie
    final captureSvc = ref.read(photoCaptureServiceProvider);
    final path = await captureSvc.capture();

    if (!mounted) return;
    if (path == null) {
      setState(() => _state = _GateState.failed);
      return;
    }
    _selfiePath = path;

    setState(() => _state = _GateState.verifying);

    // 2. Extract embedding from selfie
    final faceSvc = ref.read(faceVerificationServiceProvider);
    final selfieEmb = await faceSvc.extractEmbedding(path);

    if (!mounted) return;

    // 3. Get profile embedding (compute from path if not yet in state)
    final profileState = ref.read(profilePhotoProvider);
    List<double> profileEmb = profileState.embedding ?? [];

    if (profileEmb.isEmpty && profileState.photoPath != null) {
      // Re-compute embedding from the stored photo path (e.g. after app restart)
      profileEmb = await faceSvc.extractEmbedding(profileState.photoPath!);
      if (mounted) {
        ref.read(profilePhotoProvider.notifier).setEmbedding(profileEmb);
      }
    }

    if (!mounted) return;

    // 4. Compare
    final result = faceSvc.compare(selfieEmb, profileEmb);

    _attempts++;

    switch (result) {
      case FaceVerificationResult.match:
        setState(() => _state = _GateState.verified);
        widget.onVerified();
        break;

      case FaceVerificationResult.webUnsupported:
        setState(() => _state = _GateState.webUnsupported);
        break;

      case FaceVerificationResult.noMatch:
      case FaceVerificationResult.error:
        if (_attempts >= AppConstants.maxSelfieAttempts) {
          setState(() => _state = _GateState.hardBlocked);
          _showHardBlockAlert();
        } else {
          setState(() => _state = _GateState.failed);
        }
        break;
    }
  }

  void _showHardBlockAlert() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.lock_outline,
            color: FimmsColors.gradeCritical,
            size: 44,
          ),
          title: const Text(
            'Verification Failed',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'You have exceeded ${AppConstants.maxSelfieAttempts} face '
            'verification attempts.\n\n'
            'This inspection session is now locked. Please contact your '
            'supervisor to reset your session.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: FimmsColors.gradeCritical),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    });
  }

  // ── Computed style helpers ────────────────────────────────────────────────

  Color get _borderColor {
    switch (_state) {
      case _GateState.verified:
        return FimmsColors.gradeExcellent;
      case _GateState.failed:
        return FimmsColors.gradeCritical;
      case _GateState.hardBlocked:
        return FimmsColors.gradeCritical;
      case _GateState.webUnsupported:
        return FimmsColors.gradeAverage;
      case _GateState.noProfilePhoto:
        return FimmsColors.gradeAverage;
      default:
        return FimmsColors.outline;
    }
  }

  IconData get _headerIcon {
    switch (_state) {
      case _GateState.verified:
        return Icons.verified_user;
      case _GateState.hardBlocked:
        return Icons.lock;
      case _GateState.webUnsupported:
        return Icons.phonelink_off_outlined;
      case _GateState.noProfilePhoto:
        return Icons.person_off_outlined;
      default:
        return Icons.face_retouching_natural;
    }
  }

  Color get _headerIconColor {
    switch (_state) {
      case _GateState.verified:
        return FimmsColors.gradeExcellent;
      case _GateState.failed:
      case _GateState.hardBlocked:
        return FimmsColors.gradeCritical;
      case _GateState.webUnsupported:
      case _GateState.noProfilePhoto:
        return FimmsColors.gradeAverage;
      default:
        return FimmsColors.primary;
    }
  }

  Color get _headerIconBg => _headerIconColor.withValues(alpha: 0.1);

  String get _subtitle {
    switch (_state) {
      case _GateState.verified:
        return 'Identity confirmed — form unlocked';
      case _GateState.hardBlocked:
        return 'Session locked after too many failures';
      case _GateState.webUnsupported:
        return 'Requires the FIMMS mobile app';
      case _GateState.noProfilePhoto:
        return 'Profile photo not yet set';
      default:
        return 'Take a selfie to verify your identity';
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────

class _WebBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FimmsColors.gradeAverage.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FimmsColors.gradeAverage.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.phone_android_outlined,
              color: FimmsColors.gradeAverage, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Face verification requires the mobile app',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: FimmsColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Identity verification uses an offline AI model that only runs '
                  'on Android and iOS devices. The inspection form is not '
                  'accessible from the web browser. Please use the FIMMS '
                  'mobile application to conduct field inspections.',
                  style: TextStyle(
                    fontSize: 12,
                    color: FimmsColors.textMuted,
                    height: 1.5,
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

class _NoProfileBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FimmsColors.gradeAverage.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FimmsColors.gradeAverage.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: FimmsColors.gradeAverage),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please set your profile photo first in the Profile tab before '
              'beginning an inspection.',
              style: TextStyle(fontSize: 12.5, color: FimmsColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleBlock extends StatelessWidget {
  final VoidCallback onTap;
  final bool failed;
  final int attemptsRemaining;
  final String? selfiePath;

  const _IdleBlock({
    required this.onTap,
    required this.failed,
    required this.attemptsRemaining,
    this.selfiePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (failed)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FimmsColors.gradeCritical.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: FimmsColors.gradeCritical.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.face_retouching_off,
                    color: FimmsColors.gradeCritical, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Face not recognised. $attemptsRemaining '
                    '${attemptsRemaining == 1 ? 'attempt' : 'attempts'} remaining.',
                    style: const TextStyle(
                        fontSize: 12.5, color: FimmsColors.gradeCritical),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            // Selfie preview (if a previous attempt was made)
            if (selfiePath != null) ...[
              _PreviewAvatar(path: selfiePath!),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.camera_front),
                label: Text(failed ? 'Retry Selfie' : 'Take Selfie'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      failed ? FimmsColors.gradeCritical : FimmsColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Your selfie will be compared against your registered profile photo to '
          'confirm identity before the form can be filled.',
          style: TextStyle(fontSize: 11.5, color: FimmsColors.textMuted),
        ),
      ],
    );
  }
}

class _SpinnerBlock extends StatelessWidget {
  final String label;
  const _SpinnerBlock({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 14),
        Text(label,
            style: const TextStyle(fontSize: 13, color: FimmsColors.textMuted)),
      ],
    );
  }
}

class _HardBlockedBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FimmsColors.gradeCritical.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: FimmsColors.gradeCritical.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: const [
          Icon(Icons.lock, color: FimmsColors.gradeCritical, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Inspection form locked — maximum verification attempts exceeded. '
              'Contact your supervisor to reset this session.',
              style: TextStyle(
                  fontSize: 12.5,
                  color: FimmsColors.gradeCritical,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FimmsColors.gradeExcellent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: FimmsColors.gradeExcellent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: const [
          Icon(Icons.verified_user,
              color: FimmsColors.gradeExcellent, size: 22),
          SizedBox(width: 12),
          Text(
            'Identity verified — form unlocked',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: FimmsColors.gradeExcellent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptBadge extends StatelessWidget {
  final int attempts;
  const _AttemptBadge({required this.attempts});

  @override
  Widget build(BuildContext context) {
    if (attempts == 0) return const SizedBox.shrink();
    final remaining = AppConstants.maxSelfieAttempts - attempts;
    final color = remaining <= 1
        ? FimmsColors.gradeCritical
        : FimmsColors.gradeAverage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$remaining left',
        style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _PreviewAvatar extends StatelessWidget {
  final String path;
  const _PreviewAvatar({required this.path});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (path.startsWith('sample:')) {
      child = const Icon(Icons.image_outlined,
          color: FimmsColors.primary, size: 24);
    } else if (!kIsWeb && File(path).existsSync()) {
      child = Image.file(File(path), fit: BoxFit.cover);
    } else {
      child = const Icon(Icons.image_outlined, color: FimmsColors.textMuted);
    }
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FimmsColors.gradeCritical.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}
