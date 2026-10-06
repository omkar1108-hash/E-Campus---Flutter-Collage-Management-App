import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

/// Phone-number login: step 1 asks for the number, step 2 for the OTP.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String? get _e164 {
    final raw = _phone.text.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (raw.startsWith('+')) {
      return RegExp(r'^\+\d{8,15}$').hasMatch(raw) ? raw : null;
    }
    return RegExp(r'^\d{10}$').hasMatch(raw) ? '${AppConfig.defaultDialCode}$raw' : null;
  }

  Future<void> _sendOtp() async {
    final number = _e164;
    if (number == null) {
      showSnack(context, 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() => _busy = true);
    await context.read<AuthService>().sendOtp(
          phoneNumber: number,
          resendToken: _resendToken,
          onResendToken: (t) => _resendToken = t,
          onCodeSent: (id) {
            if (!mounted) return;
            setState(() {
              _verificationId = id;
              _busy = false;
            });
          },
          onError: (msg) {
            if (!mounted) return;
            setState(() => _busy = false);
            showSnack(context, msg);
          },
        );
  }

  Future<void> _verify() async {
    final code = _otp.text.trim();
    if (code.length != 6) {
      showSnack(context, 'Enter the 6-digit OTP.');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().verifyOtp(_verificationId!, code);
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnack(context, describeAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpStep = _verificationId != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.school, size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('E-Campus',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    otpStep ? 'Enter the OTP sent to ${_e164 ?? 'your phone'}' : 'Sign in with your mobile number',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!otpStep)
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile number',
                        prefixText: '${AppConfig.defaultDialCode} ',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendOtp(),
                    )
                  else
                    TextField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '6-digit OTP',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : (otpStep ? _verify : _sendOtp),
                    child: _busy
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(otpStep ? 'Verify & continue' : 'Send OTP'),
                  ),
                  if (otpStep)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _verificationId = null;
                                _otp.clear();
                              }),
                      child: const Text('Change number / resend OTP'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
