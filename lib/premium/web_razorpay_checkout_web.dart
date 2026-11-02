import 'dart:async';
import 'dart:js_interop';

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

// ── JS extension type for the Razorpay handler response ─────────────────────

@JS()
extension type _RazorpayHandlerResponse._(JSAny _) implements JSAny {
  external JSString? get razorpay_payment_id;
  external JSString? get razorpay_order_id;
  external JSString? get razorpay_signature;
}

// ── Global callback slots on window ─────────────────────────────────────────
// These are set before opening the checkout and cleared in the handler.

@JS('razorpayFlutterSuccess')
external set _razorpayFlutterSuccess(JSFunction? fn);

@JS('razorpayFlutterDismiss')
external set _razorpayFlutterDismiss(JSFunction? fn);

// eval is used to inject and execute the Razorpay checkout script inline.
@JS('eval')
external void _jsEval(JSString code);

Completer<RazorpayWebResult>? _pendingCompleter;

/// Opens the Razorpay Web Checkout modal and returns the payment result.
/// Requires `checkout.js` to be loaded in index.html.
Future<RazorpayWebResult> openRazorpayWebCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String description,
  required String prefillName,
  required String prefillEmail,
  required String prefillContact,
}) {
  _pendingCompleter = Completer<RazorpayWebResult>();

  _razorpayFlutterSuccess = ((JSAny response) {
    final r = response as _RazorpayHandlerResponse;
    final result = RazorpayWebResult(
      success: true,
      dismissed: false,
      paymentId: r.razorpay_payment_id?.toDart,
      orderId: r.razorpay_order_id?.toDart,
      signature: r.razorpay_signature?.toDart,
    );
    _cleanup();
    _pendingCompleter?.complete(result);
  }).toJS;

  _razorpayFlutterDismiss = (() {
    final result = const RazorpayWebResult(success: false, dismissed: true);
    _cleanup();
    _pendingCompleter?.complete(result);
  }).toJS;

  // Sanitise string values to prevent JS injection from user-supplied data.
  final safeKey = _jsStr(keyId);
  final safeOrderId = _jsStr(orderId);
  final safeDesc = _jsStr(description);
  final safeName = _jsStr(prefillName);
  final safeEmail = _jsStr(prefillEmail);
  final safeContact = _jsStr(prefillContact);

  final script = '''
(function() {
  var options = {
    "key": "$safeKey",
    "amount": $amountPaise,
    "currency": "INR",
    "name": "KrishiMithra",
    "description": "$safeDesc",
    "order_id": "$safeOrderId",
    "handler": function(response) {
      if (window.razorpayFlutterSuccess) {
        window.razorpayFlutterSuccess(response);
      }
    },
    "prefill": {
      "name": "$safeName",
      "email": "$safeEmail",
      "contact": "$safeContact"
    },
    "theme": { "color": "#2E7D32" },
    "modal": {
      "ondismiss": function() {
        if (window.razorpayFlutterDismiss) {
          window.razorpayFlutterDismiss();
        }
      }
    }
  };
  var rzp = new Razorpay(options);
  rzp.open();
})();
''';

  _jsEval(script.toJS);

  return _pendingCompleter!.future;
}

void _cleanup() {
  _razorpayFlutterSuccess = null;
  _razorpayFlutterDismiss = null;
}

/// Escapes a string value for safe embedding inside a JS string literal.
String _jsStr(String value) =>
    value.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n');
