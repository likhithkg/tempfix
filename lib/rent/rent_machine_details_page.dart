import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'rent_model.dart';
import 'rent_list_form_page.dart';
import '../l10n/app_localizations.dart';

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

  Widget _row(String label, String value) {
    final displayLabel = label.endsWith(':') ? label : '$label:';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(displayLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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

                    const SizedBox(height: 16),

                    const Divider(),
                    const SizedBox(height: 4),

                    _row(l.machineTypeLabel, machine.type),
                    _row(l.pricePerDayLabel, '₹${machine.pricePerDay}'),
                    _row(l.locationLabel, machine.location ?? l.locationNotAvailable),
                    _row(l.ownerLabel, machine.ownerName),
                    _row(l.mobileLabel, machine.phone),

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
                                Text(AppLocalizations.of(context)!.call),

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

                            label: Text(l.whatsApp),

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