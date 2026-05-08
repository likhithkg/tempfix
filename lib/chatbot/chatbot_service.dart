import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String? _geminiKey = dotenv.env['GEMINI_API_KEY'];

  // ✅ Use v1beta (important)
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> getBotReply(String userMessage, String language) async {
    if (_geminiKey == null || _geminiKey!.isEmpty) {
      return "⚠️ AI service not configured.";
    }

    // 🌐 Language control
    String langInstruction = "";

    if (language == "KN") {
      langInstruction = "Respond in Kannada.";
    } else if (language == "HI") {
      langInstruction = "Respond in Hindi.";
    } else {
      langInstruction = "Respond in simple English.";
    }

    try {
      final uri = Uri.parse("$_geminiUrl?key=$_geminiKey");

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are KrishiMithra, an expert Indian agriculture assistant.\n"
                      "Give clear, practical, farmer-friendly answers.\n"
                      "Keep answers short and useful.\n"
                      "$langInstruction\n\n"
                      "User question: $userMessage"
                }
              ]
            }
          ]
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode != 200) {
        return "⚠️ AI server error (${response.statusCode})";
      }

      final decoded = jsonDecode(response.body);

      return decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
              ?.toString()
              .trim() ??
          "Sorry, I couldn't understand that.";
    } catch (e) {
      print("ERROR: $e");
      return "⚠️ Error connecting to AI service.";
    }
  }
}