// lib/exporter_hub/exporter_home_page.dart

import 'package:flutter/material.dart';
import 'exporter_service.dart';
import 'exporter_model.dart';
import 'exporter_form_page.dart';
import 'po_detail_page.dart';
import 'create_purchase_order_page.dart'; // ✅ Added this import (required for Buy button)

class ExporterHomePage extends StatelessWidget {
  final _service = ExporterService();

  ExporterHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exporter Hub'),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExporterFormPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ExportProduct>>(
        stream: _service.getExportProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(child: Text('No export products listed yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    product.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${product.quantity} • ${product.location}'),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('₹${product.pricePerUnit}'),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          // ✅ Navigate to CreatePurchaseOrderPage with product data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreatePurchaseOrderPage(listingData: product),
                            ),
                          );
                        },
                        child: const Text('Buy'),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Show simple product detail popup
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(product.productName),
                        content: Text(
                          'Farmer: ${product.farmerName}\n'
                          'Qty: ${product.quantity}\n'
                          'Price: ₹${product.pricePerUnit}\n'
                          'Location: ${product.location}\n\n'
                          '${product.description}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
