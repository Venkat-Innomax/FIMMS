import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../shared_widgets/responsive_scaffold.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _mobileCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _error;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_mobileCtrl.text.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _otpSent = true;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length < 4) {
      setState(() => _error = 'Enter the OTP sent to your mobile.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset link sent — check your registered mobile.'),
        backgroundColor: FimmsColors.success,
      ),
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Row(
        children: [
          if (!isMobile) const Expanded(flex: 5, child: _HeroPanel()),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      32,
                      isMobile ? 32 + MediaQuery.paddingOf(context).top : 48,
                      32,
                      32 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile) ...[
                          const FimmsBrandMark(fontSize: 20),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Reset Password',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _otpSent
                              ? 'Enter the OTP sent to ${_mobileCtrl.text}'
                              : 'Enter your registered mobile number to receive a reset OTP.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: FimmsColors.textMuted),
                        ),
                        const SizedBox(height: 28),
                        if (!_otpSent) ...[
                          TextField(
                            controller: _mobileCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Registered Mobile Number',
                              hintText: 'e.g. 9000368915',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _sendOtp(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: const TextStyle(
                                    color: FimmsColors.danger, fontSize: 13)),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _sendOtp,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send),
                              label: Text(_loading ? 'Sending...' : 'Send OTP'),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'One-Time Password (OTP)',
                              hintText: '6-digit OTP',
                              prefixIcon: Icon(Icons.lock_clock_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _verifyOtp(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 4),
                            Text(_error!,
                                style: const TextStyle(
                                    color: FimmsColors.danger, fontSize: 13)),
                          ],
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _otpSent = false),
                            child: const Text('← Change mobile number'),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _verifyOtp,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.verified_outlined),
                              label: Text(_loading ? 'Verifying...' : 'Verify & Reset'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Back to Login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FimmsColors.primary, FimmsColors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_reset, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Forgot your\npassword?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No worries. Enter your registered mobile number\nand we\'ll send you a reset OTP.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
