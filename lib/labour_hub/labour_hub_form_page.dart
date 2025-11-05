import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'labour_model.dart';
import 'labour_hub_service.dart';

class LabourHubFormPage extends StatefulWidget {
  final Labour? labour;

  const LabourHubFormPage({Key? key, this.labour}) : super(key: key);

  @override
  _LabourHubFormPageState createState() => _LabourHubFormPageState();
}

class _LabourHubFormPageState extends State<LabourHubFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = LabourHubService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _available = true;

  @override
  void initState() {
    super.initState();
    if (widget.labour != null) {
      _nameController.text = widget.labour!.name;
      _skillController.text = widget.labour!.skill;
      _locationController.text = widget.labour!.location;
      _contactController.text = widget.labour!.contact;
      _available = widget.labour!.available;
    }
  }

  Future<void> _saveLabour() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in")),
      );
      return;
    }

    final newLabour = Labour(
      id: widget.labour?.id ?? "",
      name: _nameController.text.trim(),
      skill: _skillController.text.trim(),
      location: _locationController.text.trim(),
      contact: _contactController.text.trim(),
      available: _available,
      createdBy: widget.labour?.createdBy ?? user.uid,
    );

    try {
      if (widget.labour == null) {
        await _service.addLabour(newLabour);
      } else {
        await _service.updateLabour(newLabour.id, newLabour);
      }

      Navigator.pop(context, true); // ✅ go back after saving
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.labour == null ? "Add Labour" : "Edit Labour"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ✅ back button works
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                controller: _skillController,
                decoration: const InputDecoration(labelText: "Skill"),
                validator: (v) => v == null || v.isEmpty ? "Enter skill" : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Location"),
                validator: (v) => v == null || v.isEmpty ? "Enter location" : null,
              ),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: "Contact"),
                validator: (v) => v == null || v.isEmpty ? "Enter contact" : null,
              ),
              SwitchListTile(
                title: const Text("Available"),
                value: _available,
                onChanged: (val) {
                  setState(() => _available = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveLabour,
                icon: const Icon(Icons.save),
                label: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}