import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 added
import 'labour_model.dart';
import 'labour_hub_service.dart';
import 'labour_hub_form_page.dart';
import 'labour_hub_detail_page.dart';

class LabourHubListingPage extends StatefulWidget {
  const LabourHubListingPage({Key? key}) : super(key: key);

  @override
  State<LabourHubListingPage> createState() => _LabourHubListingPageState();
}

class _LabourHubListingPageState extends State<LabourHubListingPage> {
  final LabourHubService _service = LabourHubService();
  late Future<List<Labour>> _labourListFuture;

  String _searchQuery = '';
  String _selectedSkill = 'All';
  bool _sortByName = true;

  @override
  void initState() {
    super.initState();
    _fetchLabours();
  }

  void _fetchLabours() {
    setState(() {
      _labourListFuture = _service.getAllLabours();
    });
  }

  Future<void> _openForm({Labour? labour}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LabourHubFormPage(labour: labour),
      ),
    );

    if (result == true) {
      _fetchLabours();
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this labour entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _service.deleteLabour(id);
              _fetchLabours();
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _callLabour(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid; // 👈 get current user

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Labour Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.green.shade700,
        actions: [
          // Sort Button
          IconButton(
            icon: Icon(
              _sortByName ? Icons.sort_by_alpha : Icons.sort,
              color: Colors.white,
            ),
            tooltip: _sortByName ? "Sort by Skill" : "Sort by Name",
            onPressed: () {
              setState(() {
                _sortByName = !_sortByName;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Search bar
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or location',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Dropdown filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSkill,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                    items: ['All', 'Farmer', 'Harvester', 'Plumber', 'Electrician']
                        .map((skill) => DropdownMenuItem(
                              value: skill,
                              child: Text(skill),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSkill = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Labour>>(
        future: _labourListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading labour data'));
          }

          var labours = snapshot.data ?? [];

          // Apply search filter
          labours = labours.where((labour) {
            return labour.name.toLowerCase().contains(_searchQuery) ||
                labour.location.toLowerCase().contains(_searchQuery);
          }).toList();

          // Apply skill filter
          if (_selectedSkill != 'All') {
            labours = labours.where((labour) => labour.skill == _selectedSkill).toList();
          }

          // Apply sorting
          labours.sort((a, b) => _sortByName
              ? a.name.compareTo(b.name)
              : a.skill.compareTo(b.skill));

          if (labours.isEmpty) {
            return const Center(
              child: Text(
                'No labour entries found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: labours.length,
            itemBuilder: (context, index) {
              final labour = labours[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabourHubDetailPage(labour: labour),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          labour.available ? Colors.green.shade50 : Colors.red.shade50,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: labour.available ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          labour.available ? Icons.check_circle : Icons.cancel,
                          color: labour.available ? Colors.green : Colors.red,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        labour.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.work, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(labour.skill),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(labour.location),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.blue, size: 28),
                            onPressed: () => _callLabour(labour.contact),
                          ),
                          if (labour.createdBy == currentUserId) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _openForm(labour: labour),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(labour.id),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text("Add Labour"),
        backgroundColor: Colors.green,
      ),
    );
  }
}