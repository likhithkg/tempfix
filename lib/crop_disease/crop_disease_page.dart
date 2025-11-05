import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CropDiseasePage extends StatefulWidget {
  const CropDiseasePage({super.key});

  @override
  State<CropDiseasePage> createState() => _CropDiseasePageState();
}

class _CropDiseasePageState extends State<CropDiseasePage> {
  Uint8List? _imageBytes;
  bool _loading = false;
  String _result = '';
  String _classification = '';
  String _medicine = '';

  final String apiKey = '9sQv8oViRPbMXJveFAiMM3iWtVV8WnwkjIyfJv8rBauD2oZmDt';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imageBytes = await picked.readAsBytes();

    setState(() {
      _imageBytes = imageBytes;
      _loading = true;
      _result = '';
      _classification = '';
      _medicine = '';
    });

    await _sendToAPI(imageBytes, picked.name);
  }

  Future<void> _sendToAPI(Uint8List imageBytes, String fileName) async {
    try {
      final uri = Uri.parse('https://api.plant.id/v2/health_assessment');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Api-Key'] = apiKey
        ..fields['organs'] = 'leaf'
        ..files.add(http.MultipartFile.fromBytes('images', imageBytes, filename: fileName));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      setState(() => _loading = false);

      if (response.statusCode == 200) {
        final decoded = json.decode(respStr);
        final diseases = decoded['health_assessment']['diseases'];

        if (diseases != null && diseases.isNotEmpty) {
  final disease = diseases[0];
  final diseaseName = disease['name'] ?? 'Unknown';
  final classification = disease['classification']?['kingdom'] ?? 'Unknown';
  final suggestedMedicine = _suggestMedicine(diseaseName);

  setState(() {
    _result = "✅ Disease: $diseaseName";
    _classification = "🧬 Group: $classification";
    _medicine = "💊 Medicine: $suggestedMedicine";
  });
} else {
  setState(() => _result = "🌱 No disease detected.");
}
      } else {
        setState(() => _result = "❌ API Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _result = "❌ Error: $e";
      });
    }
  }

  String _suggestMedicine(String disease) {
    final map = {
      "Leaf spot": "Copper Oxychloride",
      "Blight": "Carbendazim",
      "Powdery mildew": "Sulphur-based fungicide",
      "Downy mildew": "Metalaxyl",
      "Rust": "Hexaconazole",
      "Early Blight": "Mancozeb + Carbendazim",
      "Late Blight": "Metalaxyl + Mancozeb",
    };

    for (var key in map.keys) {
      if (disease.toLowerCase().contains(key.toLowerCase())) {
        return map[key]!;
      }
    }

    return "Consult local expert";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Disease Detector"),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Center(
                      child: _imageBytes != null
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Image"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                ),
                const SizedBox(height: 24),
                if (_result.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        if (_classification.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_classification, style: const TextStyle(fontSize: 16, color: Colors.indigo)),
                          ),
                        if (_medicine.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_medicine, style: const TextStyle(fontSize: 16, color: Colors.teal)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}