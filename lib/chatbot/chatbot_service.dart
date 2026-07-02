import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String _geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static String _langInstruction(String langCode) {
    switch (langCode) {
      case 'kn': return 'Respond in Kannada (ಕನ್ನಡ).';
      case 'hi': return 'Respond in Hindi (हिंदी).';
      case 'ta': return 'Respond in Tamil (தமிழ்).';
      case 'te': return 'Respond in Telugu (తెలుగు).';
      case 'mr': return 'Respond in Marathi (मराठी).';
      default:   return 'Respond in simple English.';
    }
  }

  Future<String> getBotReply(String userMessage, String langCode) async {
    if (_geminiKey.isEmpty) {
      return '⚠️ AI service not configured. Please add GEMINI_API_KEY to .env';
    }
    final prompt =
        'You are KrishiMithra, an expert Indian agriculture assistant.\n'
        'Give clear, practical, farmer-friendly answers.\n'
        'Keep answers concise (under 200 words).\n'
        '${_langInstruction(langCode)}\n\n'
        'User question: $userMessage';
    return _callGemini(prompt);
  }

  /// Calls Gemini to translate/adapt a [contextHint] from the local knowledge
  /// base into [langCode], keeping it relevant to [userMessage].
  Future<String> getBotReplyWithContext(
      String userMessage, String langCode, String contextHint) async {
    if (_geminiKey.isEmpty) {
      return '⚠️ AI service not configured. Please add GEMINI_API_KEY to .env';
    }
    final prompt =
        'You are KrishiMithra, an expert Indian agriculture assistant.\n'
        '${_langInstruction(langCode)}\n'
        'Use the reference information below to answer the farmer\'s question accurately.\n'
        'Keep the response practical and under 200 words.\n\n'
        'Reference information (in English):\n$contextHint\n\n'
        'Farmer\'s question: $userMessage';
    return _callGemini(prompt);
  }

  Future<String> _callGemini(String prompt) async {
    try {
      final uri = Uri.parse('$_geminiUrl?key=$_geminiKey');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );
      if (response.statusCode != 200) {
        return '⚠️ AI server error (${response.statusCode}). Please try again.';
      }
      final decoded = jsonDecode(response.body);
      return decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
              ?.toString()
              .trim() ??
          'Sorry, I could not generate a response.';
    } catch (_) {
      return '⚠️ Unable to connect to AI service. Check your internet connection.';
    }
  }
}