import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/libre_translate_service.dart';

// ─── Scan beam painter ────────────────────────────────────────────────────────

class _ScanPainter extends CustomPainter {
  final double progress;
  _ScanPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final gridP = Paint()
      ..color = const Color(0xFF69F0AE).withValues(alpha: 0.12)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 8; i++) {
      canvas.drawLine(
        Offset(size.width * i / 8, 0), Offset(size.width * i / 8, size.height), gridP);
      canvas.drawLine(
        Offset(0, size.height * i / 8), Offset(size.width, size.height * i / 8), gridP);
    }

    final brP = Paint()
      ..color = const Color(0xFF69F0AE).withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const b = 22.0;
    const m = 10.0;
    _bracket(canvas, brP, const Offset(m, m), b, true, true);
    _bracket(canvas, brP, Offset(size.width - m, m), b, false, true);
    _bracket(canvas, brP, Offset(m, size.height - m), b, true, false);
    _bracket(canvas, brP, Offset(size.width - m, size.height - m), b, false, false);

    final y = progress * size.height;
    final beamRect = Rect.fromLTWH(0, y - 38, size.width, 76);
    canvas.drawRect(
      beamRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF69F0AE).withValues(alpha: 0.55),
            const Color(0xFF69F0AE).withValues(alpha: 0.85),
            const Color(0xFF69F0AE).withValues(alpha: 0.55),
            Colors.transparent,
          ],
          stops: const [0, 0.25, 0.5, 0.75, 1],
        ).createShader(beamRect),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0xFF69F0AE).withValues(alpha: 0.9)
        ..strokeWidth = 1.5,
    );
  }

  void _bracket(Canvas c, Paint p, Offset corner, double len, bool left, bool top) {
    final dx = left ? 1.0 : -1.0;
    final dy = top ? 1.0 : -1.0;
    c.drawLine(corner, corner + Offset(dx * len, 0), p);
    c.drawLine(corner, corner + Offset(0, dy * len), p);
  }

  @override
  bool shouldRepaint(_ScanPainter o) => o.progress != progress;
}

// ─── Leaf glow painter (empty state) ─────────────────────────────────────────

class _LeafGlowPainter extends CustomPainter {
  final double pulse;
  _LeafGlowPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * (0.38 + pulse * 0.06);
    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF69F0AE).withValues(alpha: 0.22 + pulse * 0.1),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_LeafGlowPainter o) => o.pulse != pulse;
}

// ─── Embedded disease knowledge base (PlantVillage 38-class dataset) ──────────

class _DInfo {
  final String cat, sym, treat, prev;
  const _DInfo(this.cat, this.sym, this.treat, this.prev);
}

// Keys match the lowercase label returned by the HuggingFace model
const Map<String, _DInfo> _kDiseaseDb = {
  // ── Apple ──────────────────────────────────────────────────────────────────
  'apple___apple_scab': _DInfo('Fungal Disease',
      'Olive-green to brown lesions on leaves and fruit. Lesions coalesce causing leaf drop and deformed fruit.',
      'Apply fungicides (captan, mancozeb) at 10-day intervals from bud break. Remove fallen leaves.',
      'Plant resistant varieties. Rake and destroy fallen leaves. Avoid overhead irrigation.'),
  'apple___black_rot': _DInfo('Fungal Disease',
      '"Frogeye" leaf spots with purple border, brown-to-black circular lesions on fruit, cankers on limbs.',
      'Prune and destroy infected wood. Apply fungicides (captan, thiophanate-methyl). Remove mummified fruit.',
      'Prune dead wood, improve air circulation, remove mummified fruit from trees and ground.'),
  'apple___cedar_apple_rust': _DInfo('Fungal Disease',
      'Bright orange-yellow spots on upper leaf surface. Tube-like structures on undersides in spring.',
      'Apply fungicides (myclobutanil, mancozeb) starting at pink bud stage through petal fall.',
      'Remove nearby cedar/juniper trees. Plant resistant apple varieties. Monitor in spring.'),

  // ── Corn / Maize ───────────────────────────────────────────────────────────
  'corn_(maize)___cercospora_leaf_spot gray_leaf_spot': _DInfo('Fungal Disease',
      'Rectangular gray-to-tan lesions bounded by leaf veins. Lesions merge causing large blighted areas.',
      'Apply foliar fungicides (strobilurin or triazole group). Remove infected crop debris after harvest.',
      'Use resistant hybrids. Practice 2-year crop rotation. Reduce leaf wetness through row orientation.'),
  'corn_(maize)___common_rust_': _DInfo('Fungal Disease',
      'Small, round golden-to-dark-brown pustules on both leaf surfaces releasing rust-coloured spores.',
      'Apply fungicides when pustules first appear. Early-season control is most effective.',
      'Plant resistant hybrids. Early planting to avoid conditions favouring rust development.'),
  'corn_(maize)___northern_leaf_blight': _DInfo('Fungal Disease',
      'Long (2.5–15 cm) elliptical gray-green to tan lesions on leaves. Turn tan with irregular borders.',
      'Apply fungicides (azoxystrobin, propiconazole) at VT growth stage. Remove crop debris.',
      'Use resistant hybrids. Rotate with non-host crops. Bury debris by tillage to reduce inoculum.'),

  // ── Grape ──────────────────────────────────────────────────────────────────
  'grape___black_rot': _DInfo('Fungal Disease',
      'Circular tan leaf lesions with dark borders. Infected berries shrivel and turn into black mummies.',
      'Apply fungicides (myclobutanil, captan) from bud break through bunch closure. Remove mummified berries.',
      'Remove mummified fruit and infected tendrils in winter. Improve air circulation by proper pruning.'),
  'grape___esca_(black_measles)': _DInfo('Fungal Disease',
      '"Tiger stripe" interveinal leaf discoloration, dark sunken berry lesions, bleached interior wood.',
      'No fully effective chemical control. Remove infected wood. Apply trunk wound protectants promptly.',
      'Avoid large pruning wounds. Make clean cuts and seal immediately. Remove infected wood promptly.'),
  'grape___leaf_blight_(isariopsis_leaf_spot)': _DInfo('Fungal Disease',
      'Angular dark-brown lesions bounded by leaf veins. Lesions coalesce causing premature leaf drop.',
      'Apply copper-based fungicides or mancozeb during the growing season after infection periods.',
      'Improve air circulation. Remove fallen leaves. Apply protective sprays before wet weather.'),

  // ── Orange ─────────────────────────────────────────────────────────────────
  'orange___haunglongbing_(citrus_greening)': _DInfo('Bacterial Disease',
      'Asymmetric blotchy yellowing of leaves, small lopsided bitter fruit, twig dieback, corky veins.',
      'No cure. Remove infected trees immediately. Control Asian citrus psyllid vector with insecticides.',
      'Use certified disease-free budwood. Control psyllid vector with regular spraying. Scout frequently.'),

  // ── Peach ──────────────────────────────────────────────────────────────────
  'peach___bacterial_spot': _DInfo('Bacterial Disease',
      'Small water-soaked spots on leaves turning purple-brown with yellow halos. Pitted, cracked fruit spots.',
      'Apply copper-based bactericides starting at bud swell. Oxytetracycline sprays during the season.',
      'Plant resistant varieties. Avoid overhead irrigation. Reduce leaf wetness duration.'),

  // ── Pepper ─────────────────────────────────────────────────────────────────
  'pepper,_bell___bacterial_spot': _DInfo('Bacterial Disease',
      'Small water-soaked circular leaf and fruit spots enlarging to brown with yellow halos.',
      'Apply copper-based bactericides preventively. Avoid working in field when foliage is wet.',
      'Use pathogen-free seed and transplants. Avoid overhead irrigation. Practise crop rotation.'),

  // ── Potato ─────────────────────────────────────────────────────────────────
  'potato___early_blight': _DInfo('Fungal Disease',
      'Dark brown-to-black lesions with concentric rings (bull\'s-eye pattern) on older leaves first.',
      'Apply fungicides (chlorothalonil, mancozeb, azoxystrobin) preventively. Remove infected leaves.',
      'Use certified seed tubers. Maintain adequate nitrogen nutrition. Rotate crops on a 3–4 year cycle.'),
  'potato___late_blight': _DInfo('Fungal Disease',
      'Water-soaked pale-green lesions turning dark brown-black. White mycelium on undersides in humid weather. Brown rot in tubers.',
      'Apply metalaxyl or cymoxanil immediately. Remove and destroy infected plants and tubers without delay.',
      'Use certified disease-free seed. Plant resistant varieties. Destroy volunteer plants. Improve soil drainage.'),

  // ── Squash ─────────────────────────────────────────────────────────────────
  'squash___powdery_mildew': _DInfo('Fungal Disease',
      'White-to-gray powdery coating on leaf surfaces and stems. Leaves yellow and die prematurely.',
      'Apply potassium bicarbonate, sulfur, or triazole fungicides. Remove heavily infected leaves.',
      'Plant resistant varieties. Ensure good air circulation. Avoid excess nitrogen fertilisation.'),

  // ── Strawberry ─────────────────────────────────────────────────────────────
  'strawberry___leaf_scorch': _DInfo('Fungal Disease',
      'Small purple-to-dark-brown spots coalescing across leaves. Severely infected leaves turn brown and die.',
      'Apply fungicides (captan, thiram) starting at early bloom. Remove infected leaves promptly.',
      'Plant disease-free runners. Renovate beds by mowing and thinning after harvest. Avoid overhead irrigation.'),

  // ── Tomato ─────────────────────────────────────────────────────────────────
  'tomato___bacterial_spot': _DInfo('Bacterial Disease',
      'Small water-soaked leaf, stem, and fruit spots turning brown with yellow halos. Raised scab-like fruit spots.',
      'Apply copper-based bactericides preventively. Remove infected parts. Avoid working in wet fields.',
      'Use certified disease-free seed. Practise crop rotation. Avoid overhead irrigation. Stake plants.'),
  'tomato___early_blight': _DInfo('Fungal Disease',
      'Dark brown spots with concentric rings (bull\'s-eye) on lower leaves first. Yellow tissue surrounds lesions.',
      'Apply fungicides (chlorothalonil, mancozeb) when disease appears. Remove lower infected leaves. Stake plants.',
      'Rotate crops 3 years. Remove debris. Mulch to prevent soil splash. Use resistant varieties where available.'),
  'tomato___late_blight': _DInfo('Fungal Disease',
      'Water-soaked pale-green lesions turning dark brown-black on leaves and stems. White fuzzy growth in humidity. Greasy dark fruit patches.',
      'Apply metalaxyl or cymoxanil immediately. Remove and destroy infected plants without delay.',
      'Plant resistant varieties. Avoid overhead irrigation. Improve air circulation. Destroy volunteer plants.'),
  'tomato___leaf_mold': _DInfo('Fungal Disease',
      'Pale green-to-yellow spots on upper leaf surface. Olive-green-to-gray velvety mold on undersides.',
      'Apply fungicides (chlorothalonil, mancozeb). Improve greenhouse ventilation. Reduce relative humidity below 85%.',
      'Use resistant varieties. Improve air circulation. Reduce leaf wetness. Avoid overcrowding plants.'),
  'tomato___septoria_leaf_spot': _DInfo('Fungal Disease',
      'Small circular spots with dark border and gray-white center containing tiny black dots. Starts on lower leaves. Rapid defoliation.',
      'Apply fungicides (chlorothalonil, copper). Remove infected lower leaves. Stake plants for airflow.',
      'Rotate crops 2–3 years. Remove crop debris. Avoid overhead irrigation. Mulch around plant base.'),
  'tomato___spider_mites two-spotted_spider_mite': _DInfo('Pest (Mite)',
      'Fine stippling or bronzing on leaves. Fine webbing on leaf undersides. Leaves yellow and drop. Worse in hot, dry conditions.',
      'Apply acaricides (abamectin, bifenazate) to leaf undersides. Introduce predatory mites for biological control.',
      'Avoid excess nitrogen. Maintain plant moisture. Avoid broad-spectrum pesticides that kill natural enemies.'),
  'tomato___target_spot': _DInfo('Fungal Disease',
      'Round-to-irregular brown spots with concentric rings on leaves, stems, and fruit. Premature defoliation.',
      'Apply fungicides (azoxystrobin, boscalid). Remove infected plant material. Improve air circulation.',
      'Crop rotation. Avoid overhead irrigation. Remove plant debris. Use mulch to prevent soil splash.'),
  'tomato___tomato_yellow_leaf_curl_virus': _DInfo('Viral Disease',
      'Upward curling and yellowing of young leaves. Stunted plant growth. Dramatically reduced fruit set.',
      'No cure — remove and destroy infected plants immediately to stop spread. Control whitefly vector.',
      'Use resistant varieties. Control whitefly with insecticides and reflective mulch. Install insect screens.'),
  'tomato___tomato_mosaic_virus': _DInfo('Viral Disease',
      'Mosaic pattern of light and dark green on leaves. Leaf distortion, mottling, and fern-leaf symptoms.',
      'No cure — remove and destroy infected plants. Sterilise tools with bleach. Control aphid vectors.',
      'Use disease-free seeds. Wash hands before handling plants. Avoid tobacco products near plants. Control aphids.'),
};

// ─── Page ─────────────────────────────────────────────────────────────────────

class CropDiseasePage extends StatefulWidget {
  const CropDiseasePage({super.key});

  @override
  State<CropDiseasePage> createState() => _CropDiseasePageState();
}

class _CropDiseasePageState extends State<CropDiseasePage>
    with TickerProviderStateMixin {

  Uint8List? _imageBytes;
  bool _loading = false;

  String disease = '';
  String category = '';
  String severity = '';
  String symptoms = '';
  String treatment = '';
  String prevention = '';
  String confidence = '';

  String _language = 'EN';

  final _picker = ImagePicker();
  final String? _plantIdKey = dotenv.env['PLANTID_API_KEY'];
  final String? _hfKey      = dotenv.env['HUGGINGFACE_API_KEY'];
  static const _plantIdUrl  = 'https://plant.id/api/v3/health_assessment';
  static const _hfModel     =
      'linkanjarad/plant-disease-classification-mobilenet_v2_0.35_224';

  late AnimationController _fadeCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scanAnim = _scanCtrl; // linear 0→1 repeat
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _clearResults();
    });
  }

  void _clearResults() {
    disease = '';
    category = '';
    severity = '';
    symptoms = '';
    treatment = '';
    prevention = '';
    confidence = '';
    _fadeCtrl.reset();
  }

  // ─── Analysis entry point ────────────────────────────────────────────────────

  Future<void> _analyze() async {
    if (_imageBytes == null) return;

    final hasPlantId = !(_plantIdKey?.isEmpty ?? true);
    final hasHf      = !(_hfKey?.isEmpty ?? true);

    if (!hasPlantId && !hasHf) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Add PLANTID_API_KEY (plant.id) or HUGGINGFACE_API_KEY (huggingface.co) to .env'),
            backgroundColor: Color(0xFFD32F2F),
            duration: Duration(seconds: 6),
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.lightImpact();

    try {
      if (hasPlantId) {
        await _analyzeWithPlantId();
      } else {
        await _analyzeWithHuggingFace();
      }

      if (!mounted) return;

      if (_language != 'EN' && disease.isNotEmpty && !disease.startsWith('API') &&
          !disease.startsWith('Detection') && !disease.startsWith('No API')) {
        final langCode = _language == 'KN' ? 'kn' : 'hi';
        disease    = await _translate(disease,    langCode);
        category   = await _translate(category,   langCode);
        severity   = await _translate(severity,   langCode);
        symptoms   = await _translate(symptoms,   langCode);
        treatment  = await _translate(treatment,  langCode);
        prevention = await _translate(prevention, langCode);
      }

      await _saveReport();
      if (mounted) setState(() => _loading = false);
      _fadeCtrl.forward();
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          disease = 'Detection failed — check your network and try again';
        });
      }
    }
  }

  // ─── Plant.id provider ───────────────────────────────────────────────────────

  Future<void> _analyzeWithPlantId() async {
    final b64 = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';

    final res = await http.post(
      Uri.parse('$_plantIdUrl?details=description,treatment,cause&language=en'),
      headers: {
        'Content-Type': 'application/json',
        'Api-Key': _plantIdKey!,
      },
      body: jsonEncode({'images': [b64], 'health': 'all'}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      setState(() {
        _loading = false;
        disease = 'Plant.id error ${res.statusCode} — check your API key at plant.id';
      });
      return;
    }

    _parsePlantIdResponse(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─── HuggingFace provider ─────────────────────────────────────────────────────

  Future<void> _analyzeWithHuggingFace() async {
    final url = Uri.parse(
        'https://api-inference.huggingface.co/models/$_hfModel');

    var res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_hfKey',
        'Content-Type': 'application/octet-stream',
        'X-Wait-For-Model': 'true',
      },
      body: _imageBytes,
    );

    // Model may be loading on first call — retry once
    if (res.statusCode == 503) {
      await Future.delayed(const Duration(seconds: 20));
      res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_hfKey',
          'Content-Type': 'application/octet-stream',
          'X-Wait-For-Model': 'true',
        },
        body: _imageBytes,
      );
    }

    if (res.statusCode != 200) {
      setState(() {
        _loading = false;
        disease = 'HuggingFace error ${res.statusCode} — check your token';
      });
      return;
    }

    final body = jsonDecode(res.body);
    if (body is Map && body.containsKey('error')) {
      setState(() {
        _loading = false;
        disease = 'Model error: ${body['error']}';
      });
      return;
    }

    _parseHfResponse(body as List);
  }

  void _parseHfResponse(List results) {
    if (results.isEmpty) {
      disease = 'Could not classify the image — try a clearer photo';
      setState(() {});
      return;
    }

    final top   = results[0] as Map<String, dynamic>;
    final label = (top['label'] as String?) ?? '';
    final score = ((top['score']) as num?)?.toDouble() ?? 0.0;

    // Label format: "Tomato___Late_blight"
    final parts      = label.split('___');
    final cropPart   = parts[0].replaceAll('_', ' ');
    final diseasePart = parts.length > 1
        ? parts[1].replaceAll('_', ' ')
        : label.replaceAll('_', ' ');
    final isHealthy = diseasePart.toLowerCase().contains('healthy');

    confidence = '${(score * 100).toStringAsFixed(0)}%';

    if (isHealthy) {
      disease    = 'No disease detected';
      category   = 'Healthy';
      severity   = 'Low';
      symptoms   = 'The $cropPart plant appears healthy with no visible disease symptoms.';
      treatment  = 'No treatment required. Continue regular care and monitoring.';
      prevention = 'Maintain proper watering, fertilisation, and regular crop inspection.';
      setState(() {});
      return;
    }

    disease  = '$cropPart — $diseasePart';
    severity = score >= 0.75 ? 'High' : score >= 0.45 ? 'Medium' : 'Low';

    final info = _kDiseaseDb[label.toLowerCase()];
    if (info != null) {
      category   = info.cat;
      symptoms   = info.sym;
      treatment  = info.treat;
      prevention = info.prev;
    } else {
      // Crop not in PlantVillage dataset (e.g., rice, wheat)
      category   = _inferCategory(diseasePart);
      symptoms   = 'Visual signs consistent with $diseasePart detected in $cropPart. '
          'Confidence is $confidence — consider Plant.id for higher accuracy on '
          'crops like rice, wheat, or cotton.';
      treatment  = 'Consult a local agronomist. Apply appropriate fungicide or '
          'bactericide based on confirmed diagnosis.';
      prevention = 'Use certified disease-free seeds. Maintain proper plant spacing '
          'and crop rotation. Regular field scouting.';
    }

    setState(() {});
  }

  void _parsePlantIdResponse(Map<String, dynamic> data) {
    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) {
      disease = 'Could not read API response';
      setState(() {});
      return;
    }

    final healthyProb =
        ((result['is_healthy']?['probability']) as num?)?.toDouble() ?? 0.0;

    if (healthyProb > 0.85) {
      disease    = 'No disease detected';
      category   = 'Healthy';
      severity   = 'Low';
      symptoms   = 'The plant appears healthy with no visible disease symptoms.';
      treatment  = 'No treatment required. Continue regular care and monitoring.';
      prevention = 'Maintain proper watering, fertilisation, and regular inspection.';
      confidence = '${(healthyProb * 100).toStringAsFixed(0)}%';
      setState(() {});
      return;
    }

    final suggestions =
        (result['disease']?['suggestions'] as List?) ?? [];
    if (suggestions.isEmpty) {
      disease   = 'Unable to identify disease';
      symptoms  = 'Try retaking the photo with better lighting and focus.';
      setState(() {});
      return;
    }

    final top     = suggestions[0] as Map<String, dynamic>;
    final prob    = ((top['probability']) as num?)?.toDouble() ?? 0.0;
    final details = (top['details'] as Map<String, dynamic>?) ?? {};

    disease    = top['name']?.toString() ?? 'Unknown Disease';
    category   = _inferCategory(disease);
    confidence = '${(prob * 100).toStringAsFixed(0)}%';
    severity   = prob >= 0.75 ? 'High' : prob >= 0.45 ? 'Medium' : 'Low';

    // cause → prepended to description for symptoms field
    final cause       = details['cause']?.toString() ?? '';
    final description = details['description']?.toString() ?? '';
    symptoms = [if (cause.isNotEmpty) 'Cause: $cause', description]
        .where((s) => s.isNotEmpty)
        .join('\n\n');

    final treatObj = details['treatment'] as Map<String, dynamic>?;
    if (treatObj != null) {
      treatment = [
        treatObj['chemical']?.toString() ?? '',
        treatObj['biological']?.toString() ?? '',
      ].where((s) => s.isNotEmpty).join(' ');
      prevention = treatObj['prevention']?.toString() ?? '';
    }

    setState(() {});
  }

  String _inferCategory(String name) {
    final d = name.toLowerCase();
    if (d.contains('blight') || d.contains('rot') || d.contains('spot') ||
        d.contains('scab') || d.contains('mildew') || d.contains('rust') ||
        d.contains('smut') || d.contains('anthracnose')) {
      return 'Fungal Disease';
    }
    if (d.contains('bacterial') || d.contains('canker') ||
        d.contains('wilt') || d.contains('fire')) {
      return 'Bacterial Disease';
    }
    if (d.contains('mosaic') || d.contains('virus') ||
        d.contains('leaf curl') || d.contains('yellowing')) {
      return 'Viral Disease';
    }
    if (d.contains('deficiency') || d.contains('chlorosis')) {
      return 'Nutritional';
    }
    return 'Plant Disease';
  }

  Future<String> _translate(String text, String langCode) async {
    if (text.trim().isEmpty) return text;
    return LibreTranslateService.translateText(
        text: text, targetLanguage: langCode);
  }

  Future<void> _saveReport() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('disease_reports').add({
        'userId': user?.uid,
        'disease': disease,
        'category': category,
        'severity': severity,
        'symptoms': symptoms,
        'treatment': treatment,
        'prevention': prevention,
        'confidence': confidence,
        'timestamp': Timestamp.now(),
      });
    } catch (_) {}
  }

  // ─── Severity helpers ───────────────────────────────────────────────────────

  Color _severityColor() {
    final s = severity.toLowerCase();
    if (s.contains('high')) return const Color(0xFFD32F2F);
    if (s.contains('medium') || s.contains('moderate')) return const Color(0xFFFF8F00);
    if (s.isEmpty) {
      final d = disease.toLowerCase();
      if (d.contains('blight') || d.contains('rot') || d.contains('wilt') ||
          d.contains('rust') || d.contains('mosaic') || d.contains('canker')) {
        return const Color(0xFFD32F2F);
      }
    }
    return const Color(0xFF2E7D32);
  }

  String _severityLabel() {
    if (severity.isNotEmpty) return severity.toUpperCase();
    final d = disease.toLowerCase();
    if (d.contains('blight') || d.contains('rot') || d.contains('wilt')) return 'HIGH';
    if (d.contains('spot') || d.contains('mildew') || d.contains('scorch')) return 'MEDIUM';
    return 'LOW';
  }

  double _parseConfidence() {
    final c = confidence.replaceAll('%', '').trim();
    return (double.tryParse(c) ?? 75.0).clamp(0, 100) / 100;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF071B07),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF071B07), Color(0xFF0F2D0F), Color(0xFF163016)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(l),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImageZone(l),
                        const SizedBox(height: 14),
                        _buildLanguagePicker(l),
                        const SizedBox(height: 14),
                        _buildAnalyzeButton(l),
                        if (disease.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildResults(l),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          const Text('🌿', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.cropDiseaseDetector,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Powered by Gemini AI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image zone ─────────────────────────────────────────────────────────────

  Widget _buildImageZone(AppLocalizations l) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base: image or placeholder
            if (_imageBytes != null)
              Image.memory(_imageBytes!, fit: BoxFit.cover)
            else
              _buildEmptyZone(l),

            // Scanning overlay
            if (_loading && _imageBytes != null) ...[
              // Dimming
              Container(color: Colors.black.withValues(alpha: 0.45)),
              // Scan beam
              AnimatedBuilder(
                animation: _scanAnim,
                builder: (_, __) => RepaintBoundary(
                  child: CustomPaint(
                    painter: _ScanPainter(_scanAnim.value),
                  ),
                ),
              ),
              // "Analyzing" label
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: _DotsLabel(),
              ),
            ],

            // Corner brackets when image selected and NOT loading
            if (_imageBytes != null && !_loading)
              IgnorePointer(
                child: CustomPaint(
                  painter: _ScanPainter(2.0), // progress > 1 = only brackets shown
                ),
              ),

            // Change button when image selected and NOT loading
            if (_imageBytes != null && !_loading)
              Positioned(
                bottom: 12,
                right: 12,
                child: _glassChip(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(l.gallery,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyZone(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: const Color(0xFF69F0AE).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glow + leaf emoji
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(110, 110),
                      painter: _LeafGlowPainter(_pulseAnim.value),
                    ),
                  ),
                  Text('🌿',
                      style: TextStyle(
                          fontSize: 48 + _pulseAnim.value * 4)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Scan Your Crop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Take a clear photo of the leaf or plant',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),

          // Camera / Gallery inline buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _glassButton(
                icon: Icons.camera_alt_outlined,
                label: l.camera,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 12),
              _glassButton(
                icon: Icons.photo_library_outlined,
                label: l.gallery,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22), width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _glassChip({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // ─── Language picker ─────────────────────────────────────────────────────────

  Widget _buildLanguagePicker(AppLocalizations l) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.13), width: 1),
          ),
          child: Row(
            children: [
              Text(
                '🌐',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 8),
              Text(
                'Output Language',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _langChip('EN', l.english),
              const SizedBox(width: 6),
              _langChip('KN', l.kannada),
              const SizedBox(width: 6),
              _langChip('HI', l.hindi),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langChip(String code, String label) {
    final selected = _language == code;
    return GestureDetector(
      onTap: () => setState(() => _language = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF69F0AE).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF69F0AE).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF69F0AE)
                : Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ─── Analyze button ──────────────────────────────────────────────────────────

  Widget _buildAnalyzeButton(AppLocalizations l) {
    final enabled = _imageBytes != null && !_loading;
    return GestureDetector(
      onTap: enabled ? _analyze : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF43A047).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: enabled ? 0 : 6, sigmaY: enabled ? 0 : 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _loading ? Icons.hourglass_top_rounded : Icons.biotech_outlined,
                  color: enabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _imageBytes == null
                      ? 'Select an image first'
                      : _loading
                          ? 'Analyzing...'
                          : l.analyzeDisease,
                  style: TextStyle(
                    color: enabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Results ─────────────────────────────────────────────────────────────────

  Widget _buildResults(AppLocalizations l) {
    final sevColor = _severityColor();
    final sevLabel = _severityLabel();
    final conf = _parseConfidence();
    final isHealthy = disease.toLowerCase().contains('no disease') ||
        disease.toLowerCase().contains('healthy');

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero result card ─────────────────────────────────────────────
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disease name + severity badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHealthy ? '✅ Healthy' : '🦠 $disease',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              category,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sevColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sevColor.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Text(
                        sevLabel,
                        style: TextStyle(
                          color: sevColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Confidence bar
                if (confidence.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'AI Confidence',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        confidence,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: conf,
                      minHeight: 6,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        conf >= 0.7
                            ? const Color(0xFF69F0AE)
                            : conf >= 0.45
                                ? const Color(0xFFFFB300)
                                : const Color(0xFFEF5350),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Detail cards ──────────────────────────────────────────────────
          if (symptoms.isNotEmpty)
            _resultSection(
              emoji: '🔬',
              title: l.symptomsResult,
              value: symptoms,
              accentColor: const Color(0xFFFF8F00),
            ),

          if (treatment.isNotEmpty) ...[
            const SizedBox(height: 10),
            _resultSection(
              emoji: '💊',
              title: l.treatmentResult,
              value: treatment,
              accentColor: const Color(0xFF69F0AE),
            ),
          ],

          if (prevention.isNotEmpty) ...[
            const SizedBox(height: 10),
            _resultSection(
              emoji: '🛡️',
              title: l.preventionResult,
              value: prevention,
              accentColor: const Color(0xFF40C4FF),
            ),
          ],

          // Rescan button
          const SizedBox(height: 16),
          _glassChip(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.camera_alt_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Scan another crop',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ]),
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.14), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _resultSection({
    required String emoji,
    required String title,
    required String value,
    required Color accentColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.12), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(
                        color: accentColor.withValues(alpha: 0.2), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated "Analyzing..." label ───────────────────────────────────────────

class _DotsLabel extends StatefulWidget {
  @override
  State<_DotsLabel> createState() => _DotsLabelState();
}

class _DotsLabelState extends State<_DotsLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final dots = '.' * ((_c.value * 4).floor() % 4);
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 60),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF69F0AE).withValues(alpha: 0.35),
                    width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    'AI analyzing$dots',
                    style: const TextStyle(
                      color: Color(0xFF69F0AE),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
