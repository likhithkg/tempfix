import 'package:flutter/material.dart';
import '../theme.dart';
import '_public_scaffold.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Products and Services',
      child: _ServicesContent(),
    );
  }
}

class _ServicesContent extends StatelessWidget {
  const _ServicesContent();

  @override
  Widget build(BuildContext context) {
    return PublicBody(
      sections: [
        const PublicSection(
          title: 'KrishiMithra Products and Services',
          body: 'KrishiMithra is a comprehensive digital platform for Indian agriculture. '
              'It connects farmers, machine owners, plant sellers, agricultural labourers, '
              'exporters, and buyers on a single accessible platform.\n\n'
              'Most services on KrishiMithra are completely free. Three advanced features '
              'require a one-time premium payment for permanent access.',
        ),
        PublicSection(
          title: '',
          customContent: Column(
            children: const [
              _ServiceBlock(
                icon: Icons.agriculture_rounded,
                color: Color(0xFFE65100),
                name: 'RentHub',
                tagline: 'Farm Equipment Rental Marketplace',
                description:
                    'RentHub connects farmers who need equipment with machine owners '
                    'who have equipment available for hire. Available equipment includes '
                    'tractors, harvesters, rotavators, cultivators, seeders, threshers, '
                    'sprayers, tillers, and heavy agricultural machinery.\n\n'
                    'How it works:\n'
                    '• Machine owners create listings with photos, specifications, '
                    'availability, and contact details\n'
                    '• Farmers search by location and equipment type\n'
                    '• Farmers browse results, view machine details, contact owners, '
                    'and submit booking requests\n'
                    '• Machine owners manage bookings and update availability\n\n'
                    'Pricing for RentHub listings: Machine hire rates are set by the '
                    'machine owner and displayed in the listing. KrishiMithra does not '
                    'set or guarantee equipment hire prices.',
                freeFeatures: [
                  'Browse all machine listings — free',
                  'Search by location and type — free',
                  'View machine details and photos — free',
                  'Contact machine owners — free',
                  'Submit booking requests — free',
                  'Edit existing listings — free',
                ],
                premiumLabel: 'RentHub Premium (₹99 one-time)',
                premiumDescription:
                    'Publish new machine listings. Only required once to publish your first listing.',
              ),
              SizedBox(height: 24),
              _ServiceBlock(
                icon: Icons.local_florist_rounded,
                color: Color(0xFF2E7D32),
                name: 'GreenBazaar (Plant Vendor)',
                tagline: 'Plant and Nursery Marketplace',
                description:
                    'GreenBazaar is a marketplace for buying and selling plants, '
                    'saplings, seeds, and nursery products. Plant sellers and nursery '
                    'owners can create product listings with photos, descriptions, and '
                    'pricing. Buyers can browse, search, and order from sellers in their area.\n\n'
                    'How it works:\n'
                    '• Nursery owners and plant sellers create product listings\n'
                    '• Farmers and buyers browse listings by plant type and location\n'
                    '• Buyers place orders and contact sellers\n'
                    '• Sellers manage their inventory and orders',
                freeFeatures: [
                  'Browse plant listings — free',
                  'View product details — free',
                  'Contact sellers — free',
                  'Place orders — free',
                ],
                premiumLabel: 'Plant Vendor Premium (₹99 one-time)',
                premiumDescription:
                    'Publish plant and nursery product listings for sale.',
              ),
              SizedBox(height: 24),
              _ServiceBlock(
                icon: Icons.biotech_rounded,
                color: Color(0xFF1565C0),
                name: 'Crop Disease Detection',
                tagline: 'AI-Powered Crop Health Analysis',
                description:
                    'The Crop Disease Detection service uses machine learning models '
                    'to analyse photographs of crop leaves, stems, or plants to identify '
                    'potential diseases and provide treatment recommendations.\n\n'
                    'How it works:\n'
                    '• Farmer photographs an affected plant part\n'
                    '• The image is analysed by an AI model\n'
                    '• Results include disease identification, confidence level, and '
                    'suggested treatment or corrective measures\n\n'
                    'This service supports early detection, helping farmers take timely '
                    'action before disease spreads across a crop.',
                freeFeatures: [],
                premiumLabel: 'Crop Disease AI Premium (₹99 one-time)',
                premiumDescription:
                    'Full access to AI crop disease detection — upload photos and receive instant analysis.',
              ),
              SizedBox(height: 24),
              _ServiceBlock(
                icon: Icons.people_rounded,
                color: Color(0xFF6A1B9A),
                name: 'Labour Hub',
                tagline: 'Agricultural Labour Marketplace',
                description:
                    'Labour Hub connects farmers who need workers with agricultural '
                    'labourers seeking employment. Farmers can post job requirements; '
                    'workers can create profiles and apply for available work.\n\n'
                    'How it works:\n'
                    '• Workers create profiles with their skills, experience, daily rate, '
                    'and availability\n'
                    '• Farmers browse and search for workers by location and skill type\n'
                    '• Farmers post job openings; workers apply\n'
                    '• Both parties can view ratings and reviews\n\n'
                    'Available worker categories include field workers, machine operators, '
                    'irrigation specialists, harvesting crews, and general farm labour.',
                freeFeatures: [
                  'All Labour Hub features are free for farmers and workers',
                  'Browse and search workers — free',
                  'Post job openings — free',
                  'Create a worker profile — free',
                  'Apply for jobs — free',
                  'Contact farmers and workers — free',
                ],
                premiumLabel: null,
                premiumDescription: null,
              ),
              SizedBox(height: 24),
              _ServiceBlock(
                icon: Icons.local_shipping_rounded,
                color: Color(0xFF00695C),
                name: 'Exporter Hub',
                tagline: 'Agricultural Export Platform',
                description:
                    'Exporter Hub is a B2B platform that connects Indian farmers and '
                    'agricultural product suppliers with export buyers and export service '
                    'providers. It includes a full purchase order management workflow.\n\n'
                    'Features for farmers:\n'
                    '• Browse export product demand board\n'
                    '• Submit produce for export consideration\n'
                    '• Track purchase order progress through all stages\n\n'
                    'Features for admin/exporters:\n'
                    '• Manage purchase orders through a 13-step workflow\n'
                    '• Quality control reporting\n'
                    '• Warehouse stock management\n'
                    '• Shipment tracking\n'
                    '• Buyer relationship management\n'
                    '• Export finance dashboard',
                freeFeatures: [
                  'All Exporter Hub features are free',
                  'Browse demand board — free',
                  'Submit produce — free',
                  'Track purchase orders — free',
                ],
                premiumLabel: null,
                premiumDescription: null,
              ),
            ],
          ),
        ),
        const PublicSection(
          title: 'Additional Free Services',
          body: '• Smart Weather Forecasts: Hyper-local weather data with '
              'agriculture-specific guidance — irrigation planning, disease risk alerts, '
              'daily and hourly forecasts. Always free.\n\n'
              '• AI Chatbot: Ask agricultural questions in English, Hindi, Kannada, '
              'Tamil, Telugu, Marathi, or Malayalam. Powered by a knowledge base of '
              'farming information and a large language model. Always free.\n\n'
              '• Land Connect: A platform for land leasing arrangements and farming '
              'partnerships. Always free.',
        ),
        PublicSection(
          title: 'Summary: Free vs Premium',
          customContent: _SummaryTable(),
        ),
      ],
    );
  }
}

class _ServiceBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String tagline;
  final String description;
  final List<String> freeFeatures;
  final String? premiumLabel;
  final String? premiumDescription;

  const _ServiceBlock({
    required this.icon,
    required this.color,
    required this.name,
    required this.tagline,
    required this.description,
    required this.freeFeatures,
    required this.premiumLabel,
    required this.premiumDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: KMColors.textPrimary)),
                    Text(tagline,
                        style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(description,
              style: const TextStyle(
                  fontSize: 13,
                  color: KMColors.textSecondary,
                  height: 1.65)),
          if (freeFeatures.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Free features:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20))),
                  const SizedBox(height: 6),
                  ...freeFeatures.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('✓ $f',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                                height: 1.5)),
                      )),
                ],
              ),
            ),
          ],
          if (premiumLabel != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(premiumLabel!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(premiumDescription!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: KMColors.textSecondary,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = [
      ['RentHub — Browse, Search, Book', 'Free'],
      ['RentHub — Publish new listing', '₹99 (one-time)'],
      ['GreenBazaar — Buy / Browse plants', 'Free'],
      ['GreenBazaar — Sell / List plants', '₹99 (one-time)'],
      ['Crop Disease Detection', '₹99 (one-time)'],
      ['Labour Hub — All features', 'Free'],
      ['Exporter Hub — All features', 'Free'],
      ['Weather Forecasts', 'Free'],
      ['AI Chatbot', 'Free'],
      ['Land Connect', 'Free'],
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
      },
      border: TableBorder.all(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: KMColors.primaryDark),
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Service',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13)),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Cost',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13)),
            ),
          ],
        ),
        ...rows.map((row) {
          final isFree = row[1] == 'Free';
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(row[0],
                    style: const TextStyle(
                        fontSize: 13, color: KMColors.textPrimary)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(row[1],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isFree
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100))),
              ),
            ],
          );
        }),
      ],
    );
  }
}
