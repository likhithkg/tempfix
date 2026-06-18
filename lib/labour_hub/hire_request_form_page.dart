// lib/labour_hub/hire_request_form_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hire_request_model.dart';
import '../l10n/app_localizations.dart';

class HireRequestFormPage extends StatefulWidget {
  final String labourId;
  final String labourName;

  const HireRequestFormPage({
    Key? key,
    required this.labourId,
    required this.labourName,
  }) : super(key: key);

  @override
  State<HireRequestFormPage> createState() => _HireRequestFormPageState();
}

class _HireRequestFormPageState extends State<HireRequestFormPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  final _durationController = TextEditingController();
  String _durationUnit = 'days';
  final _workTypeController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final hireRequest = HireRequest(
        id: '', // Firestore will assign
        labourId: widget.labourId,
        requestedBy: user.uid,
        date: _selectedDate!,
        duration: int.tryParse(_durationController.text) ?? 1,
        durationUnit: _durationUnit,
        workType: _workTypeController.text.trim(),
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('hire_requests').add(hireRequest.toMap());

      if (mounted) {
        final l2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l2.hireRequestSentSuccessfully)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _workTypeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.hireLabourTitle(widget.labourName))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Duration'),
                validator: (v) => v == null || v.isEmpty ? 'Enter duration' : null,
              ),
              DropdownButtonFormField<String>(
                value: _durationUnit,
                items: ['hours', 'days']
                    .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: (val) => setState(() => _durationUnit = val!),
                decoration: InputDecoration(labelText: 'Duration Unit'),
              ),
              TextFormField(
                controller: _workTypeController,
                decoration: InputDecoration(labelText: 'Work Type'),
                validator: (v) => v == null || v.isEmpty ? 'Enter work type' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Job Location'),
                validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l.sendHireRequest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}