import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PremiumEntitlementRecord {
  final String featureId;
  final DateTime activatedAt;
  final int packageType;

  const PremiumEntitlementRecord({
    required this.featureId,
    required this.activatedAt,
    required this.packageType,
  });

  factory PremiumEntitlementRecord.fromJson(Map<String, dynamic> j) =>
      PremiumEntitlementRecord(
        featureId: j['featureId'] as String,
        activatedAt: DateTime.parse(j['activatedAt'] as String),
        packageType: (j['packageType'] as num).toInt(),
      );
}

/// Result returned by [PremiumService.createPayment].
class RazorpayCreateResult {
  final String txnid;
  final String razorpayOrderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final List<String> features;
  final String prefillName;
  final String prefillEmail;
  final String prefillContact;
  final String description;

  RazorpayCreateResult.fromJson(Map<String, dynamic> j)
      : txnid = j['txnid'] as String,
        razorpayOrderId = j['razorpayOrderId'] as String,
        keyId = j['keyId'] as String,
        amountPaise = (j['amountPaise'] as num).toInt(),
        currency = j['currency'] as String? ?? 'INR',
        features = List<String>.from(j['features'] as List),
        prefillName = (j['prefill'] as Map?)?['name'] as String? ?? 'Farmer',
        prefillEmail = (j['prefill'] as Map?)?['email'] as String? ?? '',
        prefillContact = (j['prefill'] as Map?)?['contact'] as String? ?? '',
        description = j['description'] as String? ?? 'KrishiMithra Premium';
}

class PremiumVerifyResult {
  final bool success;
  final List<String> activatedFeatures;
  final String message;

  const PremiumVerifyResult({
    required this.success,
    required this.activatedFeatures,
    required this.message,
  });
}

class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const _base = 'https://km-backend-ug96.onrender.com';

  List<PremiumEntitlementRecord>? _cache;
  DateTime? _cacheExpiry;

  Future<String?> _token() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.value(null);
    return user.getIdToken();
  }

  bool _isJson(http.Response res) {
    final ct = res.headers['content-type'] ?? '';
    return ct.contains('application/json');
  }

  void _log(String method, String url, http.Response res, {required bool hasToken}) {
    final preview = res.body.length > 500 ? res.body.substring(0, 500) : res.body;
    debugPrint('[Premium] $method $url → ${res.statusCode} auth=${hasToken ? 'yes' : 'NO'} body[:500]=$preview');
  }

  void invalidateCache() {
    _cache = null;
    _cacheExpiry = null;
  }

  Future<List<PremiumEntitlementRecord>> getEntitlements({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cache != null &&
        _cacheExpiry != null &&
        now.isBefore(_cacheExpiry!)) {
      return _cache!;
    }
    const url = '$_base/api/premium/entitlements';
    try {
      final tok = await _token();
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${tok ?? ''}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      _log('GET', url, res, hasToken: tok != null);

      if (res.statusCode == 200 && _isJson(res)) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['entitlements'] as List)
            .map((e) => PremiumEntitlementRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        _cache = list;
        _cacheExpiry = now.add(const Duration(minutes: 5));
        return list;
      }
    } catch (e) {
      debugPrint('[Premium] getEntitlements error: $e');
    }
    return _cache ?? [];
  }

  Future<bool> hasEntitlement(String featureId) async {
    final list = await getEntitlements();
    return list.any((e) => e.featureId == featureId);
  }

  /// Creates a Razorpay order on the backend for premium feature purchase.
  Future<RazorpayCreateResult> createPayment({
    required List<String> features,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    const url = '$_base/api/razorpay/create-order';
    final tok = await _token();

    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer ${tok ?? ''}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'features': features,
              'customerDetails': {
                'name': customerName ?? '',
                'email': customerEmail ?? '',
                'phone': customerPhone ?? '',
              },
            }),
          )
          .timeout(const Duration(seconds: 25));
    } on http.ClientException catch (e) {
      // XHR status 0 — CORS blocked or backend unreachable.
      debugPrint('[Premium] Network error on create-order: ${e.message}');
      throw Exception(
        'Cannot reach payment server. '
        'Check your internet connection and try again. '
        'If the problem persists, the server may be starting up — wait 30 seconds.',
      );
    } on TimeoutException {
      debugPrint('[Premium] Timeout on create-order');
      throw Exception(
        'Payment server is taking too long to respond. '
        'It may be starting up — please wait 30 seconds and try again.',
      );
    }

    _log('POST', url, res, hasToken: tok != null);

    if (res.statusCode != 200) {
      if (_isJson(res)) {
        final err = (jsonDecode(res.body) as Map)['error'] ?? 'Failed to create payment';
        throw Exception(err as String);
      }
      throw Exception(
        'Server returned HTTP ${res.statusCode}. '
        'The backend may still be starting up — please wait a moment and try again.',
      );
    }
    return RazorpayCreateResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Verifies the Razorpay payment signature on the backend and activates entitlements.
  /// Called once after the Razorpay SDK/web callback returns payment IDs.
  Future<PremiumVerifyResult> verifyAndActivate({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    const url = '$_base/api/razorpay/verify-payment';
    final tok = await _token();
    final res = await http
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${tok ?? ''}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'razorpayOrderId': razorpayOrderId,
            'razorpayPaymentId': razorpayPaymentId,
            'razorpaySignature': razorpaySignature,
          }),
        )
        .timeout(const Duration(seconds: 20));

    _log('POST', url, res, hasToken: tok != null);

    if (res.statusCode == 200 && _isJson(res)) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      invalidateCache();
      return PremiumVerifyResult(
        success: true,
        activatedFeatures: List<String>.from(data['activatedFeatures'] ?? []),
        message: data['message'] as String? ?? 'Features activated',
      );
    }

    if (_isJson(res)) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return PremiumVerifyResult(
        success: false,
        activatedFeatures: const [],
        message: data['error'] as String? ?? 'Verification failed',
      );
    }

    return PremiumVerifyResult(
      success: false,
      activatedFeatures: const [],
      message: 'Server returned HTTP ${res.statusCode}. Backend may be starting up.',
    );
  }

  /// Idempotent status check — used by PaymentResultPage to retrieve activated features.
  /// Does NOT re-verify the Razorpay signature; looks up the stored payment status.
  Future<PremiumVerifyResult> verifyPayment(String txnid) async {
    const url = '$_base/api/razorpay/payment-status';
    final tok = await _token();
    final res = await http
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${tok ?? ''}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'txnid': txnid}),
        )
        .timeout(const Duration(seconds: 15));

    _log('POST', url, res, hasToken: tok != null);

    if (res.statusCode == 200 && _isJson(res)) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) invalidateCache();
      return PremiumVerifyResult(
        success: data['success'] as bool? ?? false,
        activatedFeatures: List<String>.from(data['activatedFeatures'] ?? []),
        message: data['message'] as String? ?? '',
      );
    }

    if (_isJson(res)) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return PremiumVerifyResult(
        success: false,
        activatedFeatures: const [],
        message: data['error'] as String? ?? 'Status check failed',
      );
    }

    return PremiumVerifyResult(
      success: false,
      activatedFeatures: const [],
      message: 'Server returned HTTP ${res.statusCode}.',
    );
  }

  Future<Map<String, dynamic>> getHistory({int page = 1}) async {
    final url = '$_base/api/razorpay/payment-history?page=$page';
    final tok = await _token();
    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${tok ?? ''}',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    _log('GET', url, res, hasToken: tok != null);

    if (res.statusCode == 200 && _isJson(res)) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load payment history (HTTP ${res.statusCode})');
  }
}
