import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String? _openaiKey = dotenv.env['OPENAI_API_KEY'];
  final String? _hfKey = dotenv.env['HUGGINGFACE_API_KEY'];

  // OpenAI endpoint
  static const String _openaiUrl = 'https://api.openai.com/v1/chat/completions';
  // Hugging Face free endpoint (choose a good conversational model)
  static const String _hfUrl = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium';

  Future<String> getBotReply(String userMessage) async {
    try {
      // --- Try OpenAI first ---
      if (_openaiKey != null && _openaiKey!.isNotEmpty) {
        final response = await http.post(
          Uri.parse(_openaiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openaiKey',
          },
          body: jsonEncode({
            "model": "gpt-3.5-turbo",
            "messages": [
              {"role": "system", "content": "You are KrishiMithra, an AI farming assistant chatbot."},
              {"role": "user", "content": userMessage}
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        }
      }

      // --- If OpenAI failed, try Hugging Face ---
      if (_hfKey != null && _hfKey!.isNotEmpty) {
        final response = await http.post(
          Uri.parse(_hfUrl),
          headers: {
            'Authorization': 'Bearer $_hfKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({"inputs": userMessage}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty && data[0]['generated_text'] != null) {
            return data[0]['generated_text'];
          } else if (data['generated_text'] != null) {
            return data['generated_text'];
          }
          return "Sorry, I couldn’t understand that (empty reply).";
        } else {
          return "Error from Hugging Face: ${response.statusCode}";
        }
      }

      return "No valid API key found.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
