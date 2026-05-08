import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportListingDetailPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ExportListingDetailPage({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<ExportListingDetailPage> createState() =>
      _ExportListingDetailPageState();
}

class _ExportListingDetailPageState
    extends State<ExportListingDetailPage> {

  Future<void> callFarmer(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // 🔥 NEW FUNCTION - UPDATE STATUS
  Future<void> updateStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('export_listings')
        .doc(widget.docId)
        .update({
      'status': status,
    });

    setState(() {
      widget.data['status'] = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Listing $status successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final String farmerName = data['farmerName'] ?? 'Unknown';
    final String farmerPhone = data['farmerPhone'] ?? '';
    final String status = data['status'] ?? 'open';

    Color statusColor;
    if (status == 'approved') {
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Listing Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // PRODUCT NAME
                Text(
                  data['productName'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                // PRODUCT DETAILS
                Text("Category: ${data['category'] ?? ''}"),
                Text("Quantity: ${data['quantity'] ?? ''}"),
                Text("Price/kg: ${data['pricePerKg'] ?? ''}"),
                Text("Location: ${data['location'] ?? ''}"),

                const SizedBox(height: 10),

                // STATUS BADGE
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Status: $status",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),

                const Divider(height: 30),

                // FARMER DETAILS
                const Text(
                  "Farmer Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text("Name: $farmerName"),
                Text("Mobile: $farmerPhone"),

                const SizedBox(height: 25),

                // CALL BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text("Call Farmer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: farmerPhone.isEmpty
                        ? null
                        : () => callFarmer(farmerPhone),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 ACCEPT & REJECT BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: status == 'approved'
                            ? null
                            : () => updateStatus('approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Accept"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: status == 'rejected'
                            ? null
                            : () => updateStatus('rejected'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}