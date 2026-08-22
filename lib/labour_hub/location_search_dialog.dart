import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _kP2 = Color(0xFF2E7D32);
const _kOrange = Color(0xFFE65100);

class LocationResult {
  final String displayName;
  final double lat;
  final double lon;
  final String village;
  final String district;
  final String state;
  final String pincode;

  const LocationResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.village = '',
    this.district = '',
    this.state = '',
    this.pincode = '',
  });
}

class LocationSearchDialog extends StatefulWidget {
  final List<String> recentLocations;

  const LocationSearchDialog({super.key, this.recentLocations = const []});

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<LocationResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(q));
  }

  Future<void> _search(String query) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json&addressdetails=1&limit=6&countrycodes=in');
      final res =
          await http.get(uri, headers: {'User-Agent': 'KrishiMithra/1.0'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _results = list.map((e) {
            final addr = (e['address'] as Map<String, dynamic>?) ?? {};
            String s(String k) => (addr[k] as String? ?? '').trim();
            return LocationResult(
              displayName: e['display_name'] as String,
              lat: double.tryParse(e['lat'] as String) ?? 0,
              lon: double.tryParse(e['lon'] as String) ?? 0,
              village: s('village').isNotEmpty
                  ? s('village')
                  : s('town').isNotEmpty
                      ? s('town')
                      : s('suburb').isNotEmpty
                          ? s('suburb')
                          : s('city'),
              district: s('county').isNotEmpty ? s('county') : s('state_district'),
              state: s('state'),
              pincode: s('postcode'),
            );
          }).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showRecent =
        _ctrl.text.trim().isEmpty && widget.recentLocations.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.location_on_rounded,
                    color: _kOrange, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Search Location',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 12),

            // Search field
            TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search village, town, district…',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.grey),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kP2)))
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kP2, width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),

            // Results
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: showRecent
                  ? _buildList(
                      widget.recentLocations
                          .map((r) =>
                              LocationResult(displayName: r, lat: 0, lon: 0))
                          .toList(),
                      isRecent: true,
                    )
                  : _results.isEmpty && !_loading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              _ctrl.text.trim().length < 2
                                  ? 'Type at least 2 characters to search'
                                  : 'No results found',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ),
                        )
                      : _buildList(_results, isRecent: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<LocationResult> items, {required bool isRecent}) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final item = items[i];
        return ListTile(
          dense: true,
          leading: Icon(
            isRecent ? Icons.history_rounded : Icons.location_on_rounded,
            color: _kOrange,
            size: 20,
          ),
          title: Text(item.displayName,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }
}
