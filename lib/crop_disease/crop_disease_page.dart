import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

class CropDiseasePage extends StatefulWidget {
  const CropDiseasePage({super.key});

  @override
  State<CropDiseasePage> createState() => _CropDiseasePageState();
}

class _CropDiseasePageState extends State<CropDiseasePage>
    with SingleTickerProviderStateMixin {

  Uint8List? _imageBytes;
  bool _loading = false;

  String disease = '';
  String category = '';
  String symptoms = '';
  String treatment = '';
  String prevention = '';
  String confidence = '';

  String language = "EN";

  static const String geminiApiKey =
      "AIzaSyAg2p7PDcea9horKAhEGRoep1NsPNL5dbk";

  final picker = ImagePicker();

  late AnimationController _controller;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _imageBytes = bytes;
      disease = '';
      category = '';
      symptoms = '';
      treatment = '';
      prevention = '';
      confidence = '';
    });
  }

  Future<String> translateText(String text) async {
    if (language == "EN" || text.trim().isEmpty) return text;

    String langName = language == "KN" ? "Kannada" : "Hindi";

    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey",
    );

    final body = {
      "contents": [
        {
          "parts": [
            {"text": "Translate to $langName:\n$text"}
          ]
        }
      ]
    };

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(res.body);

    return decoded["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? text;
  }

  Future<void> _sendToGemini(Uint8List imageBytes) async {

    final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey");

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text": """
Analyze this crop disease image.

Return EXACTLY like this:

Disease: <name>
Category: <type>
Symptoms: <symptoms>
Treatment: <treatment>
Prevention: <prevention>
Confidence: <percentage>
"""
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Encode(imageBytes)
              }
            }
          ]
        }
      ]
    };

    try {

      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        setState(() {
          _loading = false;
          disease = "API Error ${res.statusCode}";
        });
        return;
      }

      final decoded = jsonDecode(res.body);

      final text =
          decoded["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

      _parseResponse(text);

      if (language != "EN") {
        disease = await translateText(disease);
        category = await translateText(category);
        symptoms = await translateText(symptoms);
        treatment = await translateText(treatment);
        prevention = await translateText(prevention);
        confidence = await translateText(confidence);
      }

      await _saveReport();

      setState(() {
        _loading = false;
      });

      _controller.forward();

    } catch (e) {

      setState(() {
        _loading = false;
        disease = "Error contacting AI";
      });
    }
  }

  void _parseResponse(String text) {

    for (final line in text.split("\n")) {

      final lower = line.toLowerCase();

      String value = "";

      if (line.contains(":")) {
        value = line.split(":").last.trim();
      } else if (line.contains("-")) {
        value = line.split("-").last.trim();
      }

      if (lower.startsWith("disease")) disease = value;
      if (lower.startsWith("category")) category = value;
      if (lower.startsWith("symptoms")) symptoms = value;
      if (lower.startsWith("treatment")) treatment = value;
      if (lower.startsWith("prevention")) prevention = value;
      if (lower.startsWith("confidence")) confidence = value;
    }

    if (disease.isEmpty) {
      disease = "Disease detected";
      symptoms = text;
    }

    setState(() {});
  }

  Future<void> _saveReport() async {

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection("disease_reports").add({
      "userId": user?.uid,
      "disease": disease,
      "category": category,
      "symptoms": symptoms,
      "treatment": treatment,
      "prevention": prevention,
      "confidence": confidence,
      "timestamp": Timestamp.now(),
    });
  }

  Widget resultTile(String title, String value, IconData icon, Color color) {

    if (value.trim().isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(value)
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget languageToggle() {
    final l = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: Text(l.english),
          selected: language == "EN",
          onSelected: (_) => setState(() => language = "EN"),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(l.kannada),
          selected: language == "KN",
          onSelected: (_) => setState(() => language = "KN"),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(l.hindi),
          selected: language == "HI",
          onSelected: (_) => setState(() => language = "HI"),
        ),
      ],
    );
  }

  Widget imageButtons() {
    final l = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: Text(l.camera),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.image),
          label: Text(l.gallery),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.cropDiseaseDetector),
        backgroundColor: Colors.green,
      ),

      body: Stack(
        children: [

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4CAF50), Color(0xffE8F5E9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                Container(
                  height: 220,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),

                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover))
                      : const Icon(Icons.image, size: 90),
                ),

                const SizedBox(height: 20),

                imageButtons(),

                const SizedBox(height: 20),

                languageToggle(),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _imageBytes == null
                      ? null
                      : () async {

                          setState(() {
                            _loading = true;
                          });

                          await _sendToGemini(_imageBytes!);
                        },

                  icon: const Icon(Icons.search),

                  label: Text(l.analyzeDisease),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                FadeTransition(
                  opacity: fade,

                  child: Column(
                    children: [

                      resultTile(l.diseaseResult, disease,
                          Icons.bug_report, Colors.red),

                      resultTile(l.categoryResult, category,
                          Icons.biotech, Colors.indigo),

                      resultTile(l.symptomsResult, symptoms,
                          Icons.warning, Colors.orange),

                      resultTile(l.treatmentResult, treatment,
                          Icons.medical_services, Colors.green),

                      resultTile(l.preventionResult, prevention,
                          Icons.shield, Colors.teal),

                      resultTile(l.confidenceResult, confidence,
                          Icons.analytics, Colors.blue),
                    ],
                  ),
                )
              ],
            ),
          ),

          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),

              child: const Center(
                child: CircularProgressIndicator(
                    color: Colors.white),
              ),
            )
        ],
      ),
    );
  }
}
