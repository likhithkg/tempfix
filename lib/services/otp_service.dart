import 'dart:convert';
import 'package:http/http.dart' as http;

class OtpService {
  static const _base = 'https://km-backend-ug96.onrender.com';

  Future<({bool success, String? error, int? retryAfterSeconds})> sendOtp({
    required String phone,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return (success: true, error: null, retryAfterSeconds: null);
      }
      final body = _parseBody(res.body);
      return (
        success: false,
        error: body['error'] as String? ?? 'Failed to send OTP',
        retryAfterSeconds: body['retryAfterSeconds'] as int?,
      );
    } catch (_) {
      return (
        success: false,
        error: 'Network error. Please check your connection.',
        retryAfterSeconds: null,
      );
    }
  }

  Future<({bool success, String? proofToken, String? error})> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'code': code}),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = _parseBody(res.body);
        return (
          success: true,
          proofToken: body['proofToken'] as String?,
          error: null,
        );
      }
      final body = _parseBody(res.body);
      return (
        success: false,
        proofToken: null,
        error: body['error'] as String? ?? 'Verification failed',
      );
    } catch (_) {
      return (
        success: false,
        proofToken: null,
        error: 'Network error. Please check your connection.',
      );
    }
  }

  Future<({bool success, String? error})> completeRegistration({
    required String phone,
    required String proofToken,
    required String idToken,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/otp/complete-registration'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'phone': phone, 'proofToken': proofToken}),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) return (success: true, error: null);
      final body = _parseBody(res.body);
      return (
        success: false,
        error: body['error'] as String? ?? 'Registration completion failed',
      );
    } catch (_) {
      return (
        success: false,
        error: 'Network error. Please check your connection.',
      );
    }
  }

  Map<String, dynamic> _parseBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
