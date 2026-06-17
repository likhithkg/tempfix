import 'package:translator/translator.dart';

class LibreTranslateService {

  static final GoogleTranslator
      _translator =
          GoogleTranslator();

  static Future<String> translateText({

    required String text,

    required String targetLanguage,

    String sourceLanguage = 'en',

  }) async {

    try {

      if (text.trim().isEmpty) {
        return text;
      }

      if (targetLanguage == 'en') {
        return text;
      }

      final translation =
          await _translator.translate(

        text,

        from: sourceLanguage,

        to: targetLanguage,
      );

      return translation.text;

    } catch (e) {

      print(
        'Translation Error: $e',
      );

      return text;
    }
  }
}