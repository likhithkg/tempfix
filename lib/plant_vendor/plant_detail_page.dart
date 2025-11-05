import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_model.dart';
import 'package:url_launcher/url_launcher.dart';

class PlantDetailPage extends StatelessWidget {
  final PlantVendor vendor;
  const PlantDetailPage({super.key, required this.vendor});

  String _formatDate(DateTime date) =>
      DateFormat.yMMMEd().add_jm().format(date);

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = (vendor.imageUrl ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(vendor.plantName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 210,
                width: double.infinity,
                color: Colors.green.shade50,
                child: hasImage
                    ? Image.network(vendor.imageUrl!, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.local_florist,
                            size: 90, color: Colors.green),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              vendor.plantName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(Icons.category, vendor.type),
                _chip(Icons.currency_rupee,
                    '₹${vendor.price.toStringAsFixed(2)}'),
                _chip(Icons.inventory_2, 'Qty: ${vendor.quantity}'),
                _chip(Icons.place, vendor.location),
              ],
            ),
            const SizedBox(height: 16),
            _section('Vendor'),
            _tile('Name', vendor.vendorName, Icons.person),
            _tile('Phone', vendor.phone, Icons.phone),
            _tile('Address', vendor.address, Icons.home),
            _tile('Posted', _formatDate(vendor.timestamp), Icons.event),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _call(vendor.phone),
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Buy flow coming soon…')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Buy'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _openMap(vendor.latitude, vendor.longitude),
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }

  Widget _tile(String k, String v, IconData icon) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(k),
      subtitle: Text(v),
    );
  }
}