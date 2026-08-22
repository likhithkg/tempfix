import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'chat_models.dart';

class ChatbotService {
  // ============================================================
  // BASE URL
  // ============================================================
  //
  // Flutter Web / Chrome → http://localhost:5000          (automatic)
  // Android Emulator     → http://10.0.2.2:5000           (automatic)
  // Physical Android     → set _usePhysicalDevice = true
  //                        and change _physicalDeviceUrl to your PC's LAN IP
  //                        e.g. http://192.168.1.100:5000
  //
  static const bool _usePhysicalDevice = false;
  static const String _physicalDeviceUrl = 'http://192.168.1.100:5000';

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _usePhysicalDevice ? _physicalDeviceUrl : 'http://10.0.2.2:5000';
      default:
        return _usePhysicalDevice ? _physicalDeviceUrl : 'http://localhost:5000';
    }
  }

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ============================================================
  // HISTORY BUILDER
  // ============================================================

  /// Converts [messages] (the full conversation including the new user message)
  /// into the history array sent to the backend.
  ///
  /// - Skips the initial greeting bot message (index 0).
  /// - Skips the last message (the current user message — sent as "message").
  /// - Limits to the most recent 10 messages for token efficiency.
  List<Map<String, String>> _buildHistory(List<ChatMessage> messages) {
    if (messages.length <= 2) return [];

    // Strip greeting (index 0) and current user message (last)
    final slice = messages.sublist(1, messages.length - 1);
    final limited = slice.length > 10 ? slice.sublist(slice.length - 10) : slice;

    return limited
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();
  }

  // ============================================================
  // PUBLIC API — called from chatbot_page.dart
  // ============================================================

  /// Called when no knowledge-base entry matched. Pure Groq reply.
  Future<String> getBotReply(
    String userMessage,
    String language,
    List<ChatMessage> history,
  ) {
    return _post(
      message: userMessage,
      language: language,
      history: _buildHistory(history),
    );
  }

  /// Called when a knowledge-base entry matched.
  /// [knowledgeContext] is the English KB answer injected as context.
  Future<String> getBotReplyWithContext(
    String userMessage,
    String language,
    String knowledgeContext,
    List<ChatMessage> history,
  ) {
    return _post(
      message: userMessage,
      language: language,
      context: knowledgeContext,
      history: _buildHistory(history),
    );
  }

  // ============================================================
  // HTTP POST → Node.js backend
  // ============================================================

  Future<String> _post({
    required String message,
    String language = 'en',
    String? context,
    List<Map<String, String>> history = const [],
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat');
    debugPrint('KM Chatbot → $uri');

    try {
      final bodyMap = <String, dynamic>{
        'message': message,
        'language': language,
        'history': history,
      };
      if (context != null && context.isNotEmpty) {
        bodyMap['context'] = context;
      }

      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(bodyMap))
          .timeout(const Duration(seconds: 60));

      debugPrint('KM Chatbot ← ${response.statusCode}');
      debugPrint('KM Chatbot body: ${response.body}');

      return _parse(response);
    } catch (e) {
      debugPrint('KM Chatbot exception: $e');
      return _friendlyError(e);
    }
  }

  // ============================================================
  // RESPONSE PARSING
  // ============================================================

  String _parse(http.Response response) {
    if (response.statusCode == 429) {
      return 'The chatbot is busy right now. Please wait a moment and try again.';
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final msg = data['message']?.toString().trim() ?? '';
        if (msg.isNotEmpty) return _clean(msg);
      }

      final error = data['error']?.toString().trim() ?? '';
      if (error.isNotEmpty) return error;
    } catch (e) {
      debugPrint('KM Chatbot parse error: $e');
    }

    return 'Sorry, I could not generate a response (${response.statusCode}). Please try again.';
  }

  String _clean(String text) {
    var result = text.trim();
    // Strip surrounding quotes that some models add
    if (result.length >= 2 &&
        result.startsWith('"') &&
        result.endsWith('"')) {
      result = result.substring(1, result.length - 1);
    }
    // Replace escaped newlines
    return result.replaceAll(r'\n', '\n').trim();
  }

  // ============================================================
  // ERROR MESSAGES
  // ============================================================

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('timeout')) {
      return 'The request timed out. Please check your connection and try again.';
    }

    if (text.contains('failed to fetch') ||
        text.contains('connection refused') ||
        text.contains('connection failed') ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network')) {
      return 'Could not connect to KrishiMithra AI server.\n\n'
          'Make sure the chatbot backend is running:\n'
          'cd km_chatbot_backend && npm run dev';
    }

    return 'Sorry, something went wrong. Please try again.';
  }
}
