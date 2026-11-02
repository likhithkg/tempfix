import 'package:flutter/material.dart';
import '../theme.dart';
import '_public_scaffold.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Premium Services & Pricing',
      child: _PricingContent(),
    );
  }
}

class _PricingContent extends StatelessWidget {
  const _PricingContent();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return PublicBody(
      sections: [
        const PublicSection(
          title: 'KrishiMithra Premium',
          body: 'Most KrishiMithra services are completely free. A small set of '
              'advanced features require a one-time payment for permanent access. '
              'There are no subscriptions, no recurring charges, and no expiry dates.',
        ),
        PublicSection(
          title: 'Premium Features',
          customContent: Column(
            children: [
              const _FeatureDetail(
                Icons.agriculture_rounded,
                'RentHub Premium',
                'renthub_premium',
                '₹99 (standalone)',
                'Allows machine owners to publish new equipment rental listings on RentHub. '
                    'All other RentHub activities are completely free:\n'
                    '• Browse and search machine listings ✓ Free\n'
                    '• View machine details ✓ Free\n'
                    '• Contact machine owners ✓ Free\n'
                    '• Book and request machines ✓ Free\n'
                    '• Edit existing listings ✓ Free\n'
                    '• Publish a NEW listing → Premium required',
                const Color(0xFFE65100),
              ),
              const SizedBox(height: 16),
              const _FeatureDetail(
                Icons.local_florist_rounded,
                'Plant Vendor Premium',
                'plant_vendor_premium',
                '₹99 (standalone)',
                'Allows nursery owners and plant sellers to list plants and nursery '
                    'products on GreenBazaar. Buying, browsing and ordering plants remains free.',
                KMColors.primary,
              ),
              const SizedBox(height: 16),
              const _FeatureDetail(
                Icons.biotech_rounded,
                'Crop Disease AI',
                'crop_disease_premium',
                '₹99 (standalone)',
                'Access to AI-powered crop disease detection. Upload a photograph of your '
                    'crop and receive instant analysis with disease identification and '
                    'treatment recommendations.',
                Color(0xFF1565C0),
              ),
            ],
          ),
        ),
        PublicSection(
          title: 'Bundle Pricing',
          customContent: Column(
            children: [
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(child: _PriceCard('1 Feature', '₹99', '• Choose any 1 premium feature\n• Permanent access', false)),
                        SizedBox(width: 16),
                        Expanded(child: _PriceCard('2 Features', '₹169', '• Choose any 2 premium features\n• Save ₹29 vs individual', false)),
                        SizedBox(width: 16),
                        Expanded(child: _PriceCard('3 Features', '₹229', '• All 3 premium features\n• Best value — save ₹68', true)),
                      ],
                    )
                  : Column(
                      children: const [
                        _PriceCard('1 Feature', '₹99', '• Choose any 1 premium feature\n• Permanent access', false),
                        SizedBox(height: 12),
                        _PriceCard('2 Features', '₹169', '• Choose any 2 premium features\n• Save ₹29 vs individual', false),
                        SizedBox(height: 12),
                        _PriceCard('3 Features', '₹229', '• All 3 premium features\n• Best value — save ₹68', true),
                      ],
                    ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upgrade Pricing',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20))),
                    SizedBox(height: 8),
                    Text(
                      'If you already own 1 feature and want to add a second, '
                      'you pay only the difference (₹169 − ₹99 = ₹70). '
                      'You are never charged for features you already own.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2E7D32),
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PublicSection(
          title: 'Payment Information',
          body: 'All payments are processed securely through PayU, an authorised '
              'Indian payment gateway.\n\n'
              'Accepted payment methods (subject to PayU availability):\n'
              '• UPI (PhonePe, GPay, Paytm, BHIM, etc.)\n'
              '• Debit and credit cards\n'
              '• Net banking\n'
              '• Digital wallets\n\n'
              'Payments are in Indian Rupees (INR) and include applicable taxes.',
        ),
        const PublicSection(
          title: 'Service Fulfilment',
          body: 'Premium features are digital services. Access is granted automatically '
              'and immediately upon successful payment verification — no waiting, '
              'no manual approval, no delivery required.\n\n'
              'You can verify your entitlements at any time from your Profile page '
              'under "Premium Features". Payment history is also accessible from the same page.',
        ),
        const PublicSection(
          title: 'Free Features',
          body: 'The following features are always free:\n\n'
              '• Weather forecasts and agricultural advisories\n'
              '• Browsing and searching any marketplace (machines, plants, jobs)\n'
              '• Viewing product and listing details\n'
              '• Contacting sellers, machine owners and job posters\n'
              '• Booking machines\n'
              '• Exporter Hub access\n'
              '• GreenBazaar browsing and ordering\n'
              '• Labour Hub browsing and hiring\n'
              '• AI Chatbot\n'
              '• Profile management\n'
              '• Language selection',
        ),
        const PublicSection(
          title: 'Refunds',
          body: 'For information about refund eligibility and how to request one, '
              'please see our Refund and Cancellation Policy.',
        ),
      ],
    );
  }
}

class _FeatureDetail extends StatelessWidget {
  final IconData icon;
  final String name;
  final String featureId;
  final String price;
  final String description;
  final Color color;

  const _FeatureDetail(
      this.icon, this.name, this.featureId, this.price, this.description, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(price,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(description,
                    style: const TextStyle(
                        fontSize: 13,
                        color: KMColors.textSecondary,
                        height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String tier, price, features;
  final bool highlight;

  const _PriceCard(this.tier, this.price, this.features, this.highlight);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? KMColors.primaryDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? Colors.transparent
              : KMColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                    color: KMColors.primaryDark.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tier,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: highlight ? Colors.white70 : KMColors.textSecondary)),
          const SizedBox(height: 4),
          Text(price,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: highlight ? Colors.white : KMColors.primaryDark)),
          const SizedBox(height: 12),
          Text(features,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.8,
                  color: highlight ? Colors.white70 : KMColors.textSecondary)),
          const SizedBox(height: 12),
          Text('One-time · Permanent',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlight ? Colors.white60 : Colors.green)),
        ],
      ),
    );
  }
}
