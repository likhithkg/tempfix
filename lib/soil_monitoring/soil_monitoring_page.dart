import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'soil_sample_model.dart';
import 'soil_service.dart';

class SoilMonitoringPage extends StatefulWidget {
  const SoilMonitoringPage({super.key});

  @override
  _SoilMonitoringPageState createState() => _SoilMonitoringPageState();
}

class _SoilMonitoringPageState extends State<SoilMonitoringPage> {
  final _formKey = GlobalKey<FormState>();
  final SoilService soilService = SoilService();

  final TextEditingController fieldController = TextEditingController();
  final TextEditingController phController = TextEditingController();
  final TextEditingController nController = TextEditingController();
  final TextEditingController pController = TextEditingController();
  final TextEditingController kController = TextEditingController();
  String soilType = "Loam";
  bool useAI = false;
  double soilScore = 0;

  double estimatePH(String fieldName, String soilType) {
    // Mock AI estimation
    return 6.5;
  }

  double calculateSoilScore(double ph, double n, double p, double k) {
    double phDeviation = (7 - ph).abs();
    double nDef = (50 - n) / 50 * 10;
    double pDef = (30 - p) / 30 * 10;
    double kDef = (30 - k) / 30 * 10;
    double score = 100 - (phDeviation * 20 + nDef + pDef + kDef);
    return score.clamp(0, 100);
  }

  String getCropRecommendation(double ph) {
    if (ph >= 6 && ph <= 7.5) return "Wheat, Maize";
    if (ph >= 5.5 && ph < 6) return "Rice, Barley";
    return "Check soil health";
  }

  String getFertilizerSuggestion(double n, double p, double k) {
    return "N:${(50 - n).clamp(0, 50).toStringAsFixed(1)}kg, "
        "P:${(30 - p).clamp(0, 30).toStringAsFixed(1)}kg, "
        "K:${(30 - k).clamp(0, 30).toStringAsFixed(1)}kg";
  }

  Future<void> saveSoilSample() async {
    if (!_formKey.currentState!.validate()) return;

    double phValue = useAI ? estimatePH(fieldController.text, soilType) : double.parse(phController.text);
    double nValue = double.parse(nController.text);
    double pValue = double.parse(pController.text);
    double kValue = double.parse(kController.text);

    soilScore = calculateSoilScore(phValue, nValue, pValue, kValue);

    SoilSample sample = SoilSample(
      id: const Uuid().v4(),
      fieldName: fieldController.text,
      ph: phValue,
      isAI: useAI,
      nitrogen: nValue,
      phosphorus: pValue,
      potassium: kValue,
      soilType: soilType,
      date: DateTime.now(),
    );

    await soilService.addSoilSample(sample);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Soil sample saved successfully")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Soil Health Monitoring")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: fieldController,
                decoration: const InputDecoration(labelText: "Field Name"),
                validator: (val) => val!.isEmpty ? "Enter field name" : null,
              ),
              Row(
                children: [
                  Checkbox(
                    value: useAI,
                    onChanged: (val) => setState(() {
                      useAI = val!;
                      if (useAI) {
                        phController.text = estimatePH(fieldController.text, soilType).toStringAsFixed(2);
                      }
                    }),
                  ),
                  const Text("Use AI Estimated pH"),
                ],
              ),
              if (!useAI)
                TextFormField(
                  controller: phController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Soil pH"),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Enter soil pH";
                    double? p = double.tryParse(val);
                    if (p == null || p < 0 || p > 14) return "Enter valid pH (0-14)";
                    return null;
                  },
                ),
              TextFormField(
                controller: nController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Nitrogen (kg)"),
                validator: (val) => val!.isEmpty ? "Enter N value" : null,
              ),
              TextFormField(
                controller: pController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Phosphorus (kg)"),
                validator: (val) => val!.isEmpty ? "Enter P value" : null,
              ),
              TextFormField(
                controller: kController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Potassium (kg)"),
                validator: (val) => val!.isEmpty ? "Enter K value" : null,
              ),
              DropdownButtonFormField<String>(
                value: soilType,
                items: ["Loam", "Sandy", "Clay", "Silt"].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => soilType = val!),
                decoration: const InputDecoration(labelText: "Soil Type"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveSoilSample,
                child: const Text("Save Sample"),
              ),
              const SizedBox(height: 20),
              if (soilScore > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Soil Health Score: ${soilScore.toStringAsFixed(1)}%",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Recommended Crops: ${getCropRecommendation(double.parse(phController.text))}"),
                    Text("Fertilizer Suggestion: ${getFertilizerSuggestion(
                      double.parse(nController.text),
                      double.parse(pController.text),
                      double.parse(kController.text),
                    )}"),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
