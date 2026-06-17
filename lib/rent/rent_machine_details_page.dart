import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'rent_model.dart';
import 'rent_list_form_page.dart';

class RentMachineDetailsPage extends StatelessWidget {
  final RentMachine machine;

  const RentMachineDetailsPage({
    super.key,
    required this.machine,
  });

  Future<void> _call(String phone) async {
    final uri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsapp(String phone) async {
    final uri = Uri.parse("https://wa.me/$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔥 IMAGE HEADER
          SizedBox(
            height: 280,
            width: double.infinity,
            child: machine.imageUrl.isNotEmpty
                ? Image.network(
                    machine.imageUrl,
                    fit: BoxFit.cover,

                    // LOADING
                    loadingBuilder: (
                      context,
                      child,
                      loadingProgress,
                    ) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },

                    // ERROR
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Image.asset(
                        'assets/farmer_logo.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/farmer_logo.png',
                    fit: BoxFit.cover,
                  ),
          ),

          /// 🔙 BACK BUTTON
          Positioned(
            top: 40,
            left: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          /// ✏️ EDIT BUTTON
          Positioned(
            top: 40,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RentListFormPage(
                        existingMachine: machine,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// 📄 DETAILS PANEL
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: ListView(
                  controller: controller,
                  children: [
                    /// NAME + PRICE
                    Text(
                      machine.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Chip(
                          label: Text(machine.type),
                        ),

                        const SizedBox(width: 8),

                        Chip(
                          backgroundColor:
                              Colors.green.shade100,
                          label: Text(
                            "₹${machine.pricePerDay}/day",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// LOCATION
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            machine.location ??
                                'Location not available',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// OWNER
                    Row(
                      children: [
                        const Icon(Icons.person),

                        const SizedBox(width: 6),

                        Text(machine.ownerName),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// PHONE
                    Row(
                      children: [
                        const Icon(Icons.phone),

                        const SizedBox(width: 6),

                        Text(machine.phone),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// ACTION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _call(machine.phone),

                            icon:
                                const Icon(Icons.call),

                            label:
                                const Text("Call"),

                            style:
                                ElevatedButton.styleFrom(
                              minimumSize:
                                  const Size.fromHeight(
                                50,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _whatsapp(machine.phone),

                            icon: const Icon(
                              Icons.message,
                            ),

                            label: const Text(
                              "WhatsApp",
                            ),

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.green,

                              minimumSize:
                                  const Size.fromHeight(
                                50,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}