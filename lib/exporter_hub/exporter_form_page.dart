import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'exporter_model.dart';
import 'exporter_service.dart';
import 'purchase_order_list_page.dart';

class ExporterFormPage extends StatefulWidget {
  const ExporterFormPage({Key? key}) : super(key: key);

  @override
  State<ExporterFormPage> createState() => _ExporterFormPageState();
}

class _ExporterFormPageState extends State<ExporterFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = ExporterService();

  final _farmerNameController = TextEditingController();
  final _farmerIdController = TextEditingController();
  final _productNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final product = ExportProduct(
      id: const Uuid().v4(),
      farmerId: _farmerIdController.text.trim(),
      farmerName: _farmerNameController.text.trim(),
      productName: _productNameController.text.trim(),
      category: _categoryController.text.trim(),
      quantity: _quantityController.text.trim(),
      pricePerUnit: _priceController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: '',
      createdAt: DateTime.now(),
    );

    await _service.addExportProduct(product);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => PurchaseOrderListPage()),
);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Export Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _farmerIdController, decoration: const InputDecoration(labelText: 'Farmer ID'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _farmerNameController, decoration: const InputDecoration(labelText: 'Farmer Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _productNameController, decoration: const InputDecoration(labelText: 'Product Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextFormField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity (e.g., 1200 kg)')),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per unit')),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 20),
              _isSubmitting ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submitForm, child: const Text('Submit Product')),
            ],
          ),
        ),
      ),
    );
  }
}
