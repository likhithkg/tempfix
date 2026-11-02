import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../premium/web_razorpay_checkout.dart';

enum RazorpayPaymentStatus { success, failed, cancelled, error }

class RazorpayPaymentResult {
  final RazorpayPaymentStatus status;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String? message;

  bool get isSuccess => status == RazorpayPaymentStatus.success;
  bool get isCancelled => status == RazorpayPaymentStatus.cancelled;
  bool get isFailed =>
      status == RazorpayPaymentStatus.failed ||
      status == RazorpayPaymentStatus.error;

  const RazorpayPaymentResult._({
    required this.status,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.message,
  });

  factory RazorpayPaymentResult.success({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) =>
      RazorpayPaymentResult._(
        status: RazorpayPaymentStatus.success,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

  factory RazorpayPaymentResult.failed({String? razorpayOrderId, String? message}) =>
      RazorpayPaymentResult._(
        status: RazorpayPaymentStatus.failed,
        razorpayOrderId: razorpayOrderId,
        message: message ?? 'Payment failed',
      );

  factory RazorpayPaymentResult.cancelled({String? razorpayOrderId}) =>
      RazorpayPaymentResult._(
        status: RazorpayPaymentStatus.cancelled,
        razorpayOrderId: razorpayOrderId,
        message: 'Payment cancelled by user',
      );

  factory RazorpayPaymentResult.error({String? razorpayOrderId, required String message}) =>
      RazorpayPaymentResult._(
        status: RazorpayPaymentStatus.error,
        razorpayOrderId: razorpayOrderId,
        message: message,
      );
}

/// Unified Razorpay payment service for Android (native SDK) and Web (JS interop).
class RazorpayPaymentService {
  RazorpayPaymentService._();
  static final RazorpayPaymentService instance = RazorpayPaymentService._();

  Razorpay? _razorpay;
  Completer<RazorpayPaymentResult>? _completer;
  String? _activeOrderId;

  void _initSdk() {
    if (kIsWeb) return;
    _razorpay ??= Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  void _reset() {
    _completer = null;
    _activeOrderId = null;
  }

  /// Opens Razorpay checkout for any payment (premium or marketplace).
  Future<RazorpayPaymentResult> startPayment({
    required String razorpayOrderId,
    required String keyId,
    required int amountPaise,
    required String description,
    required String prefillName,
    required String prefillEmail,
    required String prefillContact,
  }) async {
    _activeOrderId = razorpayOrderId;

    if (kIsWeb) {
      return _startWebPayment(
        razorpayOrderId: razorpayOrderId,
        keyId: keyId,
        amountPaise: amountPaise,
        description: description,
        prefillName: prefillName,
        prefillEmail: prefillEmail,
        prefillContact: prefillContact,
      );
    }

    return _startNativePayment(
      razorpayOrderId: razorpayOrderId,
      keyId: keyId,
      amountPaise: amountPaise,
      description: description,
      prefillName: prefillName,
      prefillEmail: prefillEmail,
      prefillContact: prefillContact,
    );
  }

  Future<RazorpayPaymentResult> _startNativePayment({
    required String razorpayOrderId,
    required String keyId,
    required int amountPaise,
    required String description,
    required String prefillName,
    required String prefillEmail,
    required String prefillContact,
  }) async {
    _initSdk();
    _completer = Completer<RazorpayPaymentResult>();

    try {
      final options = {
        'key': keyId,
        'amount': amountPaise,
        'currency': 'INR',
        'name': 'KrishiMithra',
        'description': description,
        'order_id': razorpayOrderId,
        'prefill': {
          'name': prefillName,
          'email': prefillEmail,
          'contact': prefillContact,
        },
        'theme': {'color': '#2E7D32'},
        'send_sms_hash': true,
        'external': {
          'wallets': ['paytm'],
        },
      };

      _razorpay!.open(options);
      return await _completer!.future;
    } catch (e) {
      _reset();
      return RazorpayPaymentResult.error(
        razorpayOrderId: razorpayOrderId,
        message: 'Failed to open payment: $e',
      );
    }
  }

  Future<RazorpayPaymentResult> _startWebPayment({
    required String razorpayOrderId,
    required String keyId,
    required int amountPaise,
    required String description,
    required String prefillName,
    required String prefillEmail,
    required String prefillContact,
  }) async {
    try {
      final webResult = await openRazorpayWebCheckout(
        keyId: keyId,
        orderId: razorpayOrderId,
        amountPaise: amountPaise,
        description: description,
        prefillName: prefillName,
        prefillEmail: prefillEmail,
        prefillContact: prefillContact,
      );

      if (webResult.success) {
        return RazorpayPaymentResult.success(
          razorpayOrderId: webResult.orderId ?? razorpayOrderId,
          razorpayPaymentId: webResult.paymentId ?? '',
          razorpaySignature: webResult.signature ?? '',
        );
      } else if (webResult.dismissed) {
        return RazorpayPaymentResult.cancelled(razorpayOrderId: razorpayOrderId);
      } else {
        return RazorpayPaymentResult.failed(
          razorpayOrderId: razorpayOrderId,
          message: webResult.errorDescription ?? 'Payment failed',
        );
      }
    } catch (e) {
      return RazorpayPaymentResult.error(
        razorpayOrderId: razorpayOrderId,
        message: 'Web payment error: $e',
      );
    }
  }

  // ── Native SDK callbacks ───────────────────────────────────────────────────

  void _onSuccess(PaymentSuccessResponse response) {
    final orderId = _activeOrderId ?? response.orderId;
    final completer = _completer;
    _reset();
    completer?.complete(
      RazorpayPaymentResult.success(
        razorpayOrderId: orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      ),
    );
  }

  void _onError(PaymentFailureResponse response) {
    final orderId = _activeOrderId;
    final completer = _completer;
    _reset();

    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    if (isCancelled) {
      completer?.complete(RazorpayPaymentResult.cancelled(razorpayOrderId: orderId));
    } else {
      completer?.complete(RazorpayPaymentResult.failed(
        razorpayOrderId: orderId,
        message: response.message ?? 'Payment failed',
      ));
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // External wallet selected — treat as cancelled from checkout perspective.
    final orderId = _activeOrderId;
    final completer = _completer;
    _reset();
    completer?.complete(RazorpayPaymentResult.cancelled(razorpayOrderId: orderId));
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _reset();
  }
}
