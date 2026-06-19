// lib/exporter_hub/ai_insights_page.dart
// AI Procurement Insights — derives actionable insights from Firestore data.
// Uses Gemini API (same key as chatbot) to generate textual insights.
// Falls back to rule-based local insights when API is unavailable.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../l10n/app_localizations.dart';

class AiInsightsPage extends StatefulWidget {
  const AiInsightsPage({super.key});

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  final _db = FirebaseFirestore.instance;
  bool _loading = false;
  List<_Insight> _insights = [];
  String? _error;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() { _loading = true; _error = null; });
    try {
      // 1. Gather stats from Firestore
      final posSnap = await _db.collection('purchase_orders').get();
      final productsSnap = await _db.collection('export_products').get();
      final shipmentsSnap = await _db.collection('shipments').get();

      final pos = posSnap.docs.map((d) => d.data()).toList();
      final products = productsSnap.docs.map((d) => d.data()).toList();
      final shipments = shipmentsSnap.docs.map((d) => d.data()).toList();

      // Crop frequency
      final cropCount = <String, int>{};
      for (final p in products) {
        final name = p['productName']?.toString() ?? '';
        if (name.isNotEmpty) cropCount[name] = (cropCount[name] ?? 0) + 1;
      }
      final topCrops = (cropCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .toList();

      // Average price by crop
      final priceSum = <String, double>{};
      final priceCount = <String, int>{};
      for (final p in products) {
        final name = p['productName']?.toString() ?? '';
        final price = double.tryParse(p['pricePerUnit']?.toString() ?? '0') ?? 0;
        if (name.isNotEmpty && price > 0) {
          priceSum[name] = (priceSum[name] ?? 0) + price;
          priceCount[name] = (priceCount[name] ?? 0) + 1;
        }
      }

      // District hotspots
      final districtCount = <String, int>{};
      for (final p in products) {
        final loc = (p['location']?.toString() ?? '').split(',').first.trim();
        if (loc.isNotEmpty) districtCount[loc] = (districtCount[loc] ?? 0) + 1;
      }
      final topDistricts = (districtCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(3)
          .toList();

      // Shipment revenue
      double totalRevenue = 0;
      final countryCount = <String, int>{};
      for (final s in shipments) {
        totalRevenue += (s['totalValue'] as num? ?? 0).toDouble();
        final country = s['destinationCountry']?.toString() ?? '';
        if (country.isNotEmpty) countryCount[country] = (countryCount[country] ?? 0) + 1;
      }
      final topDestinations = (countryCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(3)
          .toList();

      // PO acceptance
      final accepted = pos.where((p) {
        final s = p['status']?.toString() ?? '';
        return ['farmer_accepted', 'collected', 'qc_approved', 'exported', 'delivered'].contains(s);
      }).length;
      final acceptRate = pos.isNotEmpty ? (accepted / pos.length * 100).round() : 0;

      _stats = {
        'totalProducts': products.length,
        'totalPOs': pos.length,
        'totalShipments': shipments.length,
        'totalRevenue': totalRevenue,
        'acceptRate': acceptRate,
        'topCrops': topCrops.map((e) => '${e.key}(${e.value})').join(', '),
        'topDistricts': topDistricts.map((e) => '${e.key}(${e.value})').join(', '),
        'topDestinations': topDestinations.map((e) => '${e.key}(${e.value})').join(', '),
      };

      // 2. Generate insights (try Gemini, fallback to rule-based)
      final aiInsights = await _generateGeminiInsights(_stats);
      if (aiInsights != null) {
        _insights = aiInsights;
      } else {
        _insights = _ruleBasedInsights(
            topCrops, topDistricts, topDestinations, acceptRate, totalRevenue,
            priceSum, priceCount);
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<List<_Insight>?> _generateGeminiInsights(Map<String, dynamic> stats) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;

    final prompt = '''
You are an agricultural export procurement advisor for KrishiMithra in India.
Based on this data, provide 5 concise, actionable procurement insights:

Data:
- Total farmer listings: ${stats['totalProducts']}
- Total purchase orders: ${stats['totalPOs']}
- Total shipments: ${stats['totalShipments']}
- Total export revenue: ₹${stats['totalRevenue']}
- PO acceptance rate: ${stats['acceptRate']}%
- Top crops listed: ${stats['topCrops']}
- Top sourcing districts: ${stats['topDistricts']}
- Top export destinations: ${stats['topDestinations']}

Return a JSON array of 5 objects with keys: title (short), body (2 sentences), type (one of: supplier|crop|price|sourcing|profitability).
Only return the JSON array, no other text.
''';

    try {
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 800},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final list = jsonDecode(cleaned) as List;
        return list.map((item) => _Insight(
          title: item['title']?.toString() ?? '',
          body: item['body']?.toString() ?? '',
          type: item['type']?.toString() ?? 'crop',
        )).toList();
      }
    } catch (_) {}
    return null;
  }

  List<_Insight> _ruleBasedInsights(
    List<MapEntry<String, int>> topCrops,
    List<MapEntry<String, int>> topDistricts,
    List<MapEntry<String, int>> topDestinations,
    int acceptRate,
    double totalRevenue,
    Map<String, double> priceSum,
    Map<String, int> priceCount,
  ) {
    final insights = <_Insight>[];

    if (topCrops.isNotEmpty) {
      insights.add(_Insight(
        title: 'Top Demand: ${topCrops.first.key}',
        body: '${topCrops.first.key} has the highest listing volume (${topCrops.first.value} listings). '
            'Consider prioritizing procurement of this commodity.',
        type: 'crop',
      ));
    }

    if (topDistricts.isNotEmpty) {
      insights.add(_Insight(
        title: 'Hotspot District: ${topDistricts.first.key}',
        body: '${topDistricts.first.key} has the most active farmers (${topDistricts.first.value} listings). '
            'Field visits here could yield high procurement volumes.',
        type: 'sourcing',
      ));
    }

    if (acceptRate < 70) {
      insights.add(_Insight(
        title: 'Low PO Acceptance ($acceptRate%)',
        body: 'PO acceptance rate is below 70%. '
            'Consider reviewing price offers or delivery terms to improve farmer acceptance.',
        type: 'supplier',
      ));
    } else {
      insights.add(_Insight(
        title: 'Strong Farmer Engagement ($acceptRate%)',
        body: 'Farmer PO acceptance at $acceptRate% indicates healthy supplier relationships. '
            'Continue current pricing and communication practices.',
        type: 'supplier',
      ));
    }

    if (topDestinations.isNotEmpty) {
      insights.add(_Insight(
        title: 'Export Focus: ${topDestinations.first.key}',
        body: '${topDestinations.first.key} is your top export destination. '
            'Explore additional buyer relationships in this market.',
        type: 'profitability',
      ));
    }

    // Price insight for top crop
    if (topCrops.isNotEmpty) {
      final crop = topCrops.first.key;
      final avgPrice = priceCount[crop] != null && (priceCount[crop] ?? 0) > 0
          ? priceSum[crop]! / priceCount[crop]!
          : 0.0;
      if (avgPrice > 0) {
        insights.add(_Insight(
          title: 'Avg Procurement Price: $crop',
          body: 'Current average listing price for $crop is ₹${avgPrice.toStringAsFixed(0)}/unit. '
              'Benchmark against market rates to ensure competitive POs.',
          type: 'price',
        ));
      }
    }

    return insights;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'supplier': return Icons.people_alt_outlined;
      case 'crop': return Icons.eco_outlined;
      case 'price': return Icons.currency_rupee;
      case 'sourcing': return Icons.location_on_outlined;
      case 'profitability': return Icons.trending_up_outlined;
      default: return Icons.lightbulb_outline;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'supplier': return Colors.teal;
      case 'crop': return Colors.green;
      case 'price': return Colors.blue;
      case 'sourcing': return Colors.orange;
      case 'profitability': return Colors.indigo;
      default: return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.aiInsights),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadInsights,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating insights...'),
            ]))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadInsights, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadInsights,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats summary banner
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Wrap(spacing: 20, runSpacing: 8, children: [
                            _StatPill('${_stats['totalProducts'] ?? 0}', l.activeListings),
                            _StatPill('${_stats['totalPOs'] ?? 0}', l.totalPOs),
                            _StatPill('${_stats['totalShipments'] ?? 0}', l.shipmentDashboard),
                            _StatPill('${_stats['acceptRate'] ?? 0}%', 'Accept Rate'),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(l.aiInsights,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      ..._insights.asMap().entries.map((entry) {
                        final insight = entry.value;
                        final color = _colorForType(insight.type);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.12),
                                child: Icon(_iconForType(insight.type), color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(insight.title,
                                      style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 14, color: color)),
                                  const SizedBox(height: 6),
                                  Text(insight.body, style: const TextStyle(fontSize: 13)),
                                ],
                              )),
                            ]),
                          ),
                        );
                      }),

                      if (_insights.isEmpty)
                        Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.insights, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(l.notEnoughDataForInsights,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ]),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}

class _Insight {
  final String title;
  final String body;
  final String type;
  const _Insight({required this.title, required this.body, required this.type});
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary)),
      Text(label, style: TextStyle(fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}
