import 'package:flutter/material.dart';
import '_public_scaffold.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'About Us',
      child: _AboutContent(),
    );
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    return PublicBody(
      sections: [
        const PublicSection(
          title: 'About KrishiMithra',
          body: 'KrishiMithra is a comprehensive digital agriculture platform developed and '
              'operated by KrishiMithra Private Limited. Our mission is to empower Indian '
              'farmers and agriculture stakeholders with accessible, technology-driven services '
              'that reduce friction in everyday agricultural activities.',
        ),
        const PublicSection(
          title: 'Who We Are',
          body: 'KrishiMithra Private Limited is an Indian technology company focused on '
              'agricultural digitalisation. We build tools that connect farmers with the '
              'services, markets, buyers, labourers, and equipment they need — all in one '
              'accessible platform available in multiple Indian languages.',
        ),
        const PublicSection(
          title: 'Our Services',
          body: 'The KrishiMithra platform provides the following services:\n\n'
              '• RentHub: A marketplace for renting and listing farm equipment such as tractors, '
              'harvesters, rotavators, cultivators, seeders and heavy machinery. Machine owners '
              'can list their equipment for hire; farmers can browse, search, view details and '
              'contact or book machines in their area.\n\n'
              '• GreenBazaar (Plant Vendor): A marketplace for buying and selling plants, '
              'saplings, seeds and nursery products. Buyers can browse, order and track '
              'deliveries; sellers can manage their plant listings.\n\n'
              '• Crop Disease Detection: An AI-powered tool that analyses photographs of crop '
              'leaves or plants to identify potential diseases and provide treatment guidance. '
              'Uses machine learning models to support farmers in making timely decisions.\n\n'
              '• Labour Hub: A platform for hiring and finding agricultural labourers. Farmers '
              'can post job requirements; workers can create profiles and apply for available '
              'work. Location-based search helps connect nearby matches.\n\n'
              '• Exporter Hub: A B2B platform connecting Indian farmers with export buyers and '
              'export service providers. Includes purchase order management, quality control '
              'reporting, shipment tracking, warehouse management and AI-powered export insights.\n\n'
              '• Weather Forecasts: Hyper-local weather data with agriculture-specific guidance '
              'including irrigation planning, disease risk alerts, and farming advisories.\n\n'
              '• AI Chatbot: A conversational assistant that answers agricultural questions in '
              'multiple Indian languages using a knowledge base of farming information combined '
              'with a large language model.\n\n'
              '• Land Connect: A platform for land leasing and farming partnerships.',
        ),
        const PublicSection(
          title: 'Premium Services',
          body: 'Certain advanced features require a one-time premium payment:\n\n'
              '• RentHub Premium: Required only to publish new machine listings. Browsing, '
              'searching and booking machines is completely free.\n\n'
              '• Plant Vendor Premium: Required to list plants for sale on GreenBazaar.\n\n'
              '• Crop Disease AI Premium: Required to use the AI crop disease detection service.\n\n'
              'Premium access is a one-time payment with permanent lifetime access. '
              'There are no recurring charges or subscriptions.',
        ),
        const PublicSection(
          title: 'Technology',
          body: 'KrishiMithra is built using Flutter (cross-platform mobile and web), '
              'Firebase (authentication and real-time database), MongoDB (transaction records), '
              'Cloudinary (image storage), and a Node.js backend hosted on Render. '
              'Payment processing is handled through PayU, a regulated Indian payment gateway.',
        ),
        const PublicSection(
          title: 'Our Commitment',
          body: 'We are committed to:\n\n'
              '• Protecting user privacy and handling data responsibly\n'
              '• Maintaining transparent pricing with no hidden charges\n'
              '• Processing payments securely through authorised payment gateways\n'
              '• Providing accessible services in regional Indian languages\n'
              '• Supporting Indian farmers and the agricultural community',
        ),
      ],
    );
  }
}
