import 'package:flutter/material.dart';
import '_public_scaffold.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Terms and Conditions',
      child: _TermsContent(),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return PublicBody(
      sections: [
        const PublicSection(
          title: 'Terms and Conditions',
          body: 'Last updated: November 2026\n\n'
              'These Terms and Conditions ("Terms") govern your access to and use of the '
              'KrishiMithra platform, operated by KrishiMithra Private Limited '
              '("Company", "we", "us", "our"). By registering for or using KrishiMithra, '
              'you agree to be bound by these Terms. If you do not agree, please do not '
              'use the platform.',
        ),
        const PublicSection(
          title: '1. Definitions',
          body: '"Platform" means the KrishiMithra website and mobile application.\n'
              '"User" means any person who registers for or uses the Platform.\n'
              '"Premium Feature" means a paid, permanently unlocked feature on the Platform.\n'
              '"Transaction" means any payment made by a User for a Premium Feature.\n'
              '"Content" means any information, listings, images or data posted by Users.',
        ),
        const PublicSection(
          title: '2. Eligibility',
          body: 'You must be at least 18 years of age and legally capable of entering into '
              'binding contracts under applicable Indian law to use this platform. '
              'By creating an account, you represent that you meet these requirements.',
        ),
        const PublicSection(
          title: '3. User Registration',
          body: 'You must create an account to access most features of the platform. '
              'You are responsible for maintaining the security of your account credentials. '
              'You agree to provide accurate and current information during registration. '
              'You are responsible for all activity occurring under your account.',
        ),
        const PublicSection(
          title: '4. Platform Services',
          body: 'KrishiMithra provides the following digital services:\n\n'
              '• Weather forecasts and agricultural advisories\n'
              '• RentHub: Farm equipment rental marketplace\n'
              '• Plant Vendor / GreenBazaar: Plant marketplace\n'
              '• Crop Disease Detection: AI-based disease identification\n'
              '• Labour Hub: Agricultural labour marketplace\n'
              '• Exporter Hub: Export services and purchase order management\n'
              '• AI Chatbot: Agricultural advice assistant\n\n'
              'These are digital information and marketplace services. The Company does not '
              'directly provide agricultural equipment, labour, plants or export services — '
              'it facilitates connections between users.',
        ),
        const PublicSection(
          title: '5. Premium Features and Payments',
          body: 'Certain features require a one-time premium payment:\n\n'
              '• 1 Feature: ₹99 (RentHub, Plant Vendor, or Crop Disease AI)\n'
              '• 2 Features: ₹169 (any two of the above)\n'
              '• 3 Features: ₹229 (all three features)\n\n'
              'Premium access is a one-time payment with permanent, lifetime access. '
              'There are no subscriptions, recurring charges, or expiry dates.\n\n'
              'Payments are processed by PayU, an authorised payment gateway. '
              'Entitlements are activated only after server-side payment verification. '
              'The Company never grants premium access on the basis of an unverified '
              'client-side callback alone.',
        ),
        const PublicSection(
          title: '6. RentHub — Specific Terms',
          body: 'Browsing machine listings, searching, viewing details, contacting machine '
              'owners and booking machines is completely free.\n\n'
              'Only publishing a new machine listing requires a RentHub Premium entitlement. '
              'Editing or updating an existing listing is free.\n\n'
              'Machine owners are responsible for the accuracy of their listings, including '
              'availability, pricing and contact information. The Company does not verify '
              'the condition or safety of listed equipment.',
        ),
        const PublicSection(
          title: '7. User Content and Conduct',
          body: 'You are solely responsible for any content you post on the Platform. '
              'You agree not to post false, misleading, offensive or unlawful content. '
              'You agree not to misuse the Platform for spam, fraud or any illegal purpose. '
              'The Company reserves the right to remove content or suspend accounts '
              'that violate these Terms.',
        ),
        const PublicSection(
          title: '8. Intellectual Property',
          body: 'All platform content, branding, software and intellectual property is '
              'owned by KrishiMithra Private Limited. You may not copy, reproduce, '
              'distribute or create derivative works from our platform without prior '
              'written consent.',
        ),
        const PublicSection(
          title: '9. Limitation of Liability',
          body: 'The Platform is provided "as is" without warranties of any kind, '
              'express or implied. The Company is not liable for any indirect, incidental, '
              'special or consequential damages arising from your use of the Platform. '
              'The Company\'s maximum liability to any user shall not exceed the amount '
              'paid by that user to the Company in the 12 months preceding the claim.\n\n'
              'The Company is not responsible for the conduct of other users or the quality '
              'of services or goods exchanged between users on the Platform.',
        ),
        const PublicSection(
          title: '10. Privacy',
          body: 'Our collection and use of personal data is governed by our '
              'Privacy Policy, which forms part of these Terms.',
        ),
        const PublicSection(
          title: '11. Governing Law and Dispute Resolution',
          body: 'These Terms are governed by the laws of India. Any disputes arising '
              'from these Terms shall first be attempted to be resolved through '
              'good-faith negotiation. Unresolved disputes shall be subject to the '
              'exclusive jurisdiction of the courts in Bengaluru, Karnataka, India.\n\n'
              'For consumer disputes, you may also use the Consumer Disputes Redressal '
              'mechanism as provided under applicable Indian consumer protection law.',
        ),
        const PublicSection(
          title: '12. Modifications to Terms',
          body: 'The Company reserves the right to modify these Terms at any time. '
              'Changes will be posted on this page. Continued use of the Platform '
              'after changes are posted constitutes your acceptance of the updated Terms.',
        ),
        const PublicSection(
          title: '13. Contact',
          body: 'For questions about these Terms, please contact us at the details '
              'provided on our Contact Us page.',
        ),
      ],
    );
  }
}
