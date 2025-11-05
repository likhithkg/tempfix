import 'package:flutter/material.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_model.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlantListFormPage extends StatefulWidget {
  final PlantVendor? existingVendor;
  const PlantListFormPage({super.key, this.existingVendor});

  @override
  State<PlantListFormPage> createState() => _PlantListFormPageState();
}

class _PlantListFormPageState extends State<PlantListFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _plantNameController = TextEditingController();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final vendor = widget.existingVendor;
    if (vendor != null) {
      _plantNameController.text = vendor.plantName;
      _typeController.text = vendor.type;
      _priceController.text = vendor.price.toStringAsFixed(2);
      _quantityController.text = vendor.quantity.toString();
      _vendorNameController.text = vendor.vendorName;
      _phoneController.text = vendor.phone;
      _locationController.text = vendor.location;
      _addressController.text = vendor.address;
      _latController.text = vendor.latitude.toString();
      _lngController.text = vendor.longitude.toString();
    }
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _vendorNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final isEdit = widget.existingVendor != null;
    final currentUser = FirebaseAuth.instance.currentUser;

    final vendor = PlantVendor(
      id: isEdit ? widget.existingVendor!.id : '',
      plantName: _plantNameController.text.trim(),
      type: _typeController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
      vendorName: _vendorNameController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      address: _addressController.text.trim(),
      latitude: (double.tryParse(_latController.text.trim()) ?? 0.0).clamp(-90.0, 90.0),
      longitude: (double.tryParse(_lngController.text.trim()) ?? 0.0).clamp(-180.0, 180.0),
      timestamp: isEdit ? widget.existingVendor!.timestamp : DateTime.now(),
      imageUrl: isEdit ? widget.existingVendor!.imageUrl : null,
      createdBy: currentUser?.uid ?? '', // ✅ FIXED required field
    );

    try {
  final service = PlantVendorService();
  if (isEdit) {
    await service.updatePlantVendor( vendor);
  } else {
    await service.addPlantVendor(vendor);
  }

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit
            ? 'Listing updated successfully!'
            : 'Listing added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true); // ✅ go back & refresh listing
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
} finally {
  if (mounted) setState(() => _saving = false);
}
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingVendor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Listing' : 'Add Listing'),
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _field(
                          controller: _plantNameController,
                          label: 'Plant Name',
                          icon: Icons.local_florist,
                        ),
                        _field(
                          controller: _typeController,
                          label: 'Type (e.g., Fruit, Vegetable)',
                          icon: Icons.category,
                        ),
                        _field(
                          controller: _priceController,
                          label: 'Price (₹)',
                          icon: Icons.currency_rupee,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            final d = double.tryParse(v ?? '');
                            if (d == null || d < 0) return 'Enter valid price';
                            return null;
                          },
                        ),
                        _field(
                          controller: _quantityController,
                          label: 'Quantity',
                          icon: Icons.confirmation_num_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 0) return 'Enter valid quantity';
                            return null;
                          },
                        ),
                        _field(
                          controller: _vendorNameController,
                          label: 'Vendor Name',
                          icon: Icons.person,
                        ),
                        _field(
                          controller: _phoneController,
                          label: 'Phone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Enter Phone';
                            if (s.length < 8) return 'Enter valid phone';
                            return null;
                          },
                        ),
                        _field(
                          controller: _locationController,
                          label: 'Location',
                          icon: Icons.location_on,
                        ),
                        _field(
                          controller: _addressController,
                          label: 'Full Address',
                          icon: Icons.home,
                          maxLines: 2,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                controller: _latController,
                                label: 'Latitude (optional)',
                                icon: Icons.explore,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if ((v ?? '').isEmpty) return null;
                                  final d = double.tryParse(v!);
                                  if (d == null || d < -90 || d > 90) {
                                    return '−90 to 90';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                controller: _lngController,
                                label: 'Longitude (optional)',
                                icon: Icons.explore_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if ((v ?? '').isEmpty) return null;
                                  final d = double.tryParse(v!);
                                  if (d == null || d < -180 || d > 180) {
                                    return '−180 to 180';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: Text(isEdit ? 'Update' : 'Save'),
                            onPressed: _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}