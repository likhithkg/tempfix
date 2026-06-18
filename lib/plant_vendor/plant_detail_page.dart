// lib/plant_vendor/plant_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class PlantDetailPage extends StatelessWidget {
  final PlantVendor vendor;
  const PlantDetailPage({super.key, required this.vendor});

  String _formatDate(DateTime date) => DateFormat.yMMMEd().add_jm().format(date);

  Future<void> _call(BuildContext context, String? phone) async {
    final p = (phone ?? '').trim();
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.notProvided)),
      );
      return;
    }

    final uri = Uri.parse('tel:$p');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cannotOpenDialer)),
      );
    }
  }

  /// ✅ NEW: WhatsApp Function
  Future<void> _whatsapp(BuildContext context, String? phone) async {
    final p = (phone ?? '').trim();
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.notProvided)),
      );
      return;
    }

    final url =
        'https://wa.me/$p?text=Hi, I am interested in ${vendor.plantName}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenWhatsApp)),
      );
    }
  }

  Future<void> _openMap(BuildContext context, double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.locationNotAvailable)),
      );
      return;
    }

    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.locationNotAvailable)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final plantName =
        vendor.plantName.isNotEmpty ? vendor.plantName : l.unknownVendor;
    final rawType = vendor.type.isNotEmpty ? vendor.type : l.plant;

    final typeParts = rawType.split(' - ');
    final category = typeParts.first;
    final typeLabel =
        typeParts.length > 1 ? typeParts.sublist(1).join(' - ') : '';

    final priceText = '₹${vendor.price.toStringAsFixed(2)}';
    final qtyText = vendor.quantity.toString();
    final vendorName =
        vendor.vendorName.isNotEmpty ? vendor.vendorName : 'Unknown vendor';
    final phone = vendor.phone;
    final location =
        vendor.location.isNotEmpty ? vendor.location : 'Not provided';

    final imageUrl = (vendor.imageUrl ?? '').trim();
    final hasImage = imageUrl.isNotEmpty;

    final listedOn =
        vendor.timestamp != null ? _formatDate(vendor.timestamp) : '';

    final accent = Colors.green.shade600;
    final softBg = Colors.green.shade50;

    return Scaffold(
      appBar: AppBar(
        title: Text(plantName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _call(context, phone),
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () =>
                _openMap(context, vendor.latitude, vendor.longitude),
          ),
        ],
      ),

      /// 🔥 BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 IMAGE + ACTIONS
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: softBg,
                    child: hasImage
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.local_florist,
                                size: 90, color: Colors.green),
                          ),
                  ),
                ),

                /// 🔥 FLOATING BUTTONS
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'call',
                        backgroundColor: Colors.white,
                        foregroundColor: accent,
                        onPressed: () => _call(context, phone),
                        child: const Icon(Icons.call),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'whatsapp',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        onPressed: () => _whatsapp(context, phone),
                        child: const Icon(Icons.chat),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔹 TITLE
            Text(
              plantName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            /// 🔹 CATEGORY
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(category),
            ),

            const SizedBox(height: 16),

            /// 🔹 PRICE
            Text(
              priceText,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),

            const SizedBox(height: 16),

            /// 🔹 DETAILS
            _row("Type", rawType),
            _row("Quantity", qtyText),
            _row("Vendor", vendorName),
            _row("Location", location),
            _row("Listed on", listedOn),

            const SizedBox(height: 20),

            /// 🔹 ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _call(context, phone),
                    icon: const Icon(Icons.call),
                    label: Text(l.call),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _whatsapp(context, phone),
                    icon: const Icon(Icons.chat),
                    label: Text(l.whatsApp),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔹 DESCRIPTION
            Text(l.descriptionHeader,
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              vendor.description.isNotEmpty
                  ? vendor.description
                  : "No description provided.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child:
                  Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}