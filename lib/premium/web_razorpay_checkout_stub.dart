class RazorpayWebResult {
  final bool success;
  final bool dismissed;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorDescription;

  const RazorpayWebResult({
    required this.success,
    required this.dismissed,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorDescription,
  });
}

Future<RazorpayWebResult> openRazorpayWebCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String description,
  required String prefillName,
  required String prefillEmail,
  required String prefillContact,
}) async {
  return const RazorpayWebResult(
    success: false,
    dismissed: false,
    errorDescription: 'Razorpay web checkout is not supported on this platform',
  );
}
