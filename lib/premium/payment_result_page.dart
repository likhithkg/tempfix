import 'package:flutter/material.dart';

import '../theme.dart';
import 'premium_service.dart';

enum _ResultState { loading, success, failure, cancelled }

class PaymentResultPage extends StatefulWidget {
  final String? txnid;
  final String? initialStatus;

  const PaymentResultPage({super.key, this.txnid, this.initialStatus});

  factory PaymentResultPage.fromWebCallback({
    required String txnid,
    required String status,
  }) =>
      PaymentResultPage(txnid: txnid, initialStatus: status);

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  _ResultState _state = _ResultState.loading;
  List<String> _activatedFeatures = [];
  String _message = '';

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final txnid = widget.txnid;

    if (txnid == null || txnid.isEmpty) {
      _finish(_ResultState.failure, message: 'No transaction reference');
      return;
    }

    // Web callback: if the backend already verified and set status=success in the redirect,
    // we still call verify to ensure entitlements are activated and cache is cleared.
    final initial = widget.initialStatus;
    if (initial == 'failure') {
      _finish(_ResultState.failure, message: 'Payment was not completed');
      return;
    }
    if (initial == 'error') {
      _finish(_ResultState.failure, message: 'Payment error occurred');
      return;
    }

    // Verify with backend (ground truth)
    try {
      final result = await PremiumService.instance.verifyPayment(txnid);
      if (result.success) {
        _finish(_ResultState.success, features: result.activatedFeatures, message: result.message);
      } else {
        _finish(_ResultState.failure, message: result.message);
      }
    } catch (e) {
      _finish(_ResultState.failure, message: 'Verification error: $e');
    }
  }

  void _finish(_ResultState state, {List<String> features = const [], String message = ''}) {
    if (mounted) {
      setState(() {
        _state = state;
        _activatedFeatures = features;
        _message = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? KMColors.backgroundDark : KMColors.backgroundLight;

    return PopScope(
      canPop: _state != _ResultState.loading,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildContent(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_state) {
      case _ResultState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying payment...', style: TextStyle(fontSize: 15)),
            ],
          ),
        );

      case _ResultState.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 72, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('Payment Successful!',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: Colors.green)),
                  const SizedBox(height: 8),
                  const Text(
                    'You now have permanent access to:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  ..._activatedFeatures.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text(
                              _featureName(f),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: KMColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Go to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
          ],
        );

      case _ResultState.failure:
      case _ResultState.cancelled:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    _state == _ResultState.cancelled
                        ? Icons.cancel_rounded
                        : Icons.error_rounded,
                    size: 72,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _state == _ResultState.cancelled
                        ? 'Payment Cancelled'
                        : 'Payment Failed',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.red),
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'No amount was charged. You can try again anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: KMColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Go to Home'),
            ),
            const SizedBox(height: 16),
          ],
        );
    }
  }

  String _featureName(String id) {
    switch (id) {
      case 'renthub_premium':      return 'RentHub';
      case 'plant_vendor_premium': return 'Plant Vendor';
      case 'crop_disease_premium': return 'Crop Disease AI';
      default:                     return id;
    }
  }
}
