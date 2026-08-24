import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'chat_models.dart';

class ChatbotService {
  static const _model = 'gemini-3.6-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const _systemInstruction =
      'You are KrishiMithra AI, a friendly and knowledgeable agricultural assistant '
      'for Indian farmers. You help with crop cultivation, pest and disease management, '
      'fertilizers, irrigation techniques, market prices, weather guidance, and general '
      'farming best practices. Always respond in the language the user specifies. '
      'Keep answers practical, concise, and easy for a farmer to understand. '
      'When relevant, mention Indian context (local crop varieties, seasons, regions). '
      'Do not answer questions unrelated to agriculture or farming.';

  // ── Public API ───────────────────────────────────────────────────────────────

  Future<String> getBotReply(
    String userMessage,
    String language,
    List<ChatMessage> history,
  ) =>
      _generate(
        userMessage: userMessage,
        language: language,
        history: history,
      );

  Future<String> getBotReplyWithContext(
    String userMessage,
    String language,
    String knowledgeContext,
    List<ChatMessage> history,
  ) =>
      _generate(
        userMessage: userMessage,
        language: language,
        knowledgeContext: knowledgeContext,
        history: history,
      );

  // ── Core Gemini call ─────────────────────────────────────────────────────────

  Future<String> _generate({
    required String userMessage,
    required String language,
    String? knowledgeContext,
    List<ChatMessage> history = const [],
  }) async {
    if (_apiKey.isEmpty) {
      return 'Gemini API key is not configured. Please add GEMINI_API_KEY to your .env file.';
    }

    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    // Build contents array (history + current message)
    final contents = <Map<String, dynamic>>[];

    // Previous turns (skip greeting at index 0, skip last user message)
    final slice = history.length > 2 ? history.sublist(1, history.length - 1) : <ChatMessage>[];
    final limited = slice.length > 10 ? slice.sublist(slice.length - 10) : slice;
    for (final m in limited) {
      contents.add({
        'role': m.isUser ? 'user' : 'model',
        'parts': [{'text': m.content}],
      });
    }

    // Current user message — inject KB context as a preamble if present
    final prompt = StringBuffer();
    if (knowledgeContext != null && knowledgeContext.isNotEmpty) {
      prompt.writeln('[Relevant knowledge base context]: $knowledgeContext');
      prompt.writeln();
    }
    prompt.write('[Respond in language: $language] $userMessage');

    contents.add({
      'role': 'user',
      'parts': [{'text': prompt.toString()}],
    });

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _systemInstruction}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'topP': 0.9,
      },
    });

    debugPrint('KM Chatbot → Gemini $_model');

    try {
      final response = await http
          .post(uri,
              headers: const {'Content-Type': 'application/json'},
              body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('KM Chatbot ← ${response.statusCode}');
      return _parse(response);
    } catch (e) {
      debugPrint('KM Chatbot error: $e');
      return _friendlyError(e);
    }
  }

  // ── Response parsing ─────────────────────────────────────────────────────────

  String _parse(http.Response response) {
    if (response.statusCode == 429) {
      return 'The chatbot is busy right now. Please wait a moment and try again.';
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text']?.toString().trim() ?? '';
            if (text.isNotEmpty) return text;
          }
        }
      }

      // Gemini error response
      final error = data['error']?['message']?.toString().trim();
      if (error != null && error.isNotEmpty) return 'AI error: $error';
    } catch (e) {
      debugPrint('KM Chatbot parse error: $e');
    }

    return 'Sorry, I could not generate a response (${response.statusCode}). Please try again.';
  }

  // ── Error messages ───────────────────────────────────────────────────────────

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('timeout')) {
      return 'The request timed out. Please check your internet connection and try again.';
    }
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Sorry, something went wrong. Please try again.';
  }
}
