import 'package:flutter/foundation.dart';

import '../services/ai_proxy_service.dart';
import 'chat_models.dart';

class ChatbotService {
  static const _model = 'gemini-3.6-flash';

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

  // ── Core call via backend proxy ───────────────────────────────────────────────

  Future<String> _generate({
    required String userMessage,
    required String language,
    String? knowledgeContext,
    List<ChatMessage> history = const [],
  }) async {
    // Build history slice (skip greeting, cap at last 10 turns)
    final contents = <Map<String, dynamic>>[];
    final slice = history.length > 2 ? history.sublist(1, history.length - 1) : <ChatMessage>[];
    final limited = slice.length > 10 ? slice.sublist(slice.length - 10) : slice;
    for (final m in limited) {
      contents.add({
        'role': m.isUser ? 'user' : 'model',
        'parts': [{'text': m.content}],
      });
    }

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

    debugPrint('KM Chatbot → backend proxy ($_model)');

    try {
      final text = await AiProxyService.generateText(
        contents: contents,
        systemInstruction: {
          'parts': [{'text': _systemInstruction}],
        },
        model: _model,
        generationConfig: {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
          'topP': 0.9,
        },
      );

      debugPrint('KM Chatbot ← reply received');

      if (text.isEmpty) {
        return 'Sorry, I could not generate a response. Please try again.';
      }
      return text;
    } catch (e) {
      debugPrint('KM Chatbot error: $e');
      return _friendlyError(e);
    }
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
