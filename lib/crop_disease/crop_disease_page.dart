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
  final String? _geminiKey  = dotenv.env['GEMINI_API_KEY'];
  static const _plantIdUrl  = 'https://plant.id/api/v3/health_assessment';
  static const _geminiUrl   =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

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
    final hasGemini  = !(_geminiKey?.isEmpty ?? true);

    if (!hasPlantId && !hasGemini) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No API key configured. Add PLANTID_API_KEY or GEMINI_API_KEY to .env'),
            backgroundColor: Color(0xFFD32F2F),
            duration: Duration(seconds: 5),
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
        await _analyzeWithGemini();
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

  // ─── Gemini fallback provider ─────────────────────────────────────────────────

  Future<void> _analyzeWithGemini() async {
    final res = await http.post(
      Uri.parse('$_geminiUrl?key=$_geminiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': '''Analyze this crop leaf image for diseases.
Return ONLY this exact format, no extra text:

Disease: <name or "No disease detected">
Category: <Fungal / Bacterial / Viral / Nutritional / Healthy>
Severity: <Low / Medium / High>
Symptoms: <brief description>
Treatment: <treatment steps>
Prevention: <prevention tips>
Confidence: <percentage>'''
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(_imageBytes!),
                }
              }
            ]
          }
        ]
      }),
    );

    if (res.statusCode != 200) {
      setState(() {
        _loading = false;
        disease = 'Gemini error ${res.statusCode}';
      });
      return;
    }

    final decoded = jsonDecode(res.body);
    final text =
        decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    _parseGeminiResponse(text);
  }

  void _parseGeminiResponse(String text) {
    for (final line in text.split('\n')) {
      final lower = line.toLowerCase().trim();
      final value = line.contains(':')
          ? line.split(':').skip(1).join(':').trim()
          : '';
      if (lower.startsWith('disease'))    disease    = value;
      if (lower.startsWith('category'))   category   = value;
      if (lower.startsWith('severity'))   severity   = value;
      if (lower.startsWith('symptoms'))   symptoms   = value;
      if (lower.startsWith('treatment'))  treatment  = value;
      if (lower.startsWith('prevention')) prevention = value;
      if (lower.startsWith('confidence')) confidence = value;
    }
    if (disease.isEmpty) {
      disease  = 'Analysis complete';
      symptoms = text;
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
