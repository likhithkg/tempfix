import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/otp_service.dart';
import '../theme.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phone;
  const OtpVerificationPage({super.key, required this.phone});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _codeController = TextEditingController();
  final _otpService     = OtpService();
  bool _loading         = false;
  int  _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      _showSnack('Please enter the complete OTP');
      return;
    }
    setState(() => _loading = true);
    final result = await _otpService.verifyOtp(phone: widget.phone, code: code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success && result.proofToken != null) {
      Navigator.of(context).pop(result.proofToken);
    } else {
      _showSnack(result.error ?? 'Verification failed');
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0 || _loading) return;
    setState(() => _loading = true);
    final result = await _otpService.sendOtp(phone: widget.phone);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      _codeController.clear();
      _startResendTimer();
      _showSnack('OTP resent successfully');
    } else {
      _showSnack(result.error ?? 'Failed to resend OTP');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final maskedPhone = _maskPhone(widget.phone);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KMSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(Icons.sms_outlined, size: 64, color: primary),
                const SizedBox(height: 20),
                Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A 6-digit code was sent to $maskedPhone',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 12),
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                    filled: true,
                    fillColor: primary.withValues(alpha: 0.04),
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: (_resendCountdown > 0 || _loading) ? null : _resend,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend OTP in ${_resendCountdown}s'
                        : 'Resend OTP',
                    style: TextStyle(
                      color: (_resendCountdown > 0 || _loading) ? Colors.grey : primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '*')}${phone.substring(phone.length - 4)}';
  }
}
