import 'dart:convert';
import 'package:http/http.dart' as http;

// Central proxy for all server-side AI calls.
// API keys (Gemini, HuggingFace) never leave the backend.
class AiProxyService {
  static const _base = 'https://km-backend-ug96.onrender.com/api/ai';

  // ── Text generation (chatbot, plant advisor, AI insights) ──────────────────

  static Future<String> generateText({
    required List<Map<String, dynamic>> contents,
    Map<String, dynamic>? systemInstruction,
    String model = 'gemini-2.5-flash',
    Map<String, dynamic>? generationConfig,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'contents': contents,
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
      if (generationConfig != null) 'generationConfig': generationConfig,
    };

    final response = await http
        .post(
          Uri.parse('$_base/gemini/generate'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
      return 'The AI service is busy right now. Please wait a moment and try again.';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data['text']?.toString() ?? '';
    }
    return 'AI error: ${data['error'] ?? response.statusCode}';
  }

  // ── Vision / image analysis (crop disease detection) ───────────────────────

  static Future<Map<String, dynamic>> analyzeImage({
    required String imageBase64,
    required String prompt,
    String model = 'gemini-2.5-flash',
    String mimeType = 'image/jpeg',
    Map<String, dynamic>? generationConfig,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'imageBase64': imageBase64,
      'mimeType': mimeType,
      'prompt': prompt,
      if (generationConfig != null) 'generationConfig': generationConfig,
    };

    final response = await http
        .post(
          Uri.parse('$_base/gemini/vision'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Vision API error ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ── HuggingFace plant disease classification ────────────────────────────────

  static Future<List<dynamic>> classifyDisease({
    required String imageBase64,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base/huggingface/disease'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'imageBase64': imageBase64}),
        )
        .timeout(const Duration(seconds: 65));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) return body;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>?;
    throw Exception(data?['error'] ?? 'HuggingFace error ${response.statusCode}');
  }
}
