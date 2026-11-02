import 'package:flutter/material.dart';
import '_public_scaffold.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Privacy Policy',
      child: _PrivacyContent(),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return PublicBody(
      sections: [
        const PublicSection(
          title: 'Privacy Policy',
          body: 'Last updated: 2024\n\n'
              'KrishiMithra Private Limited ("Company", "we", "us") respects your privacy. '
              'This Privacy Policy explains how we collect, use, share and protect '
              'information about you when you use the KrishiMithra platform.',
        ),
        const PublicSection(
          title: '1. Information We Collect',
          body: 'We collect the following types of information:\n\n'
              'Account Information: When you register, we collect your name, email address, '
              'phone number and authentication credentials.\n\n'
              'Profile Information: Your profile photo, default location, language preference '
              'and any other information you voluntarily provide.\n\n'
              'Usage Information: Pages visited, features used, search queries and navigation '
              'patterns within the platform.\n\n'
              'Location Information: If you permit it, your device location is used to show '
              'nearby machines, workers and markets. Location data is not continuously tracked.\n\n'
              'Payment Information: When you make a payment, we collect your name, email and '
              'phone number for the transaction. Payment card details are NOT collected or '
              'stored by us — they are handled exclusively by PayU, our payment gateway.\n\n'
              'Device Information: Browser type, operating system and IP address for security '
              'and analytics purposes.',
        ),
        const PublicSection(
          title: '2. How We Use Your Information',
          body: 'We use your information to:\n\n'
              '• Provide and operate the KrishiMithra platform and its features\n'
              '• Authenticate your account and maintain session security\n'
              '• Process premium feature payments and manage entitlements\n'
              '• Show you relevant nearby services, equipment and workers\n'
              '• Send you important service updates and notifications\n'
              '• Improve the platform through usage analytics\n'
              '• Comply with legal obligations and prevent fraud',
        ),
        const PublicSection(
          title: '3. Payment Data',
          body: 'Payments on KrishiMithra are processed by PayU India. When you initiate '
              'a payment, you are directed to PayU\'s secure payment infrastructure. '
              'KrishiMithra does not receive or store your card number, CVV, UPI PIN '
              'or net banking credentials.\n\n'
              'We receive from PayU: transaction reference number, payment status, '
              'amount and payment mode (UPI/card/net banking). This information is stored '
              'to maintain your premium entitlements and provide payment history.',
        ),
        const PublicSection(
          title: '4. Data Sharing',
          body: 'We do not sell your personal data to third parties.\n\n'
              'We share data only with:\n\n'
              '• PayU: For payment processing\n'
              '• Firebase (Google): For authentication and real-time database services\n'
              '• MongoDB Atlas: For transaction record storage\n'
              '• Cloudinary: For image storage\n'
              '• Supabase: For profile image storage\n\n'
              'All third-party service providers are bound by data protection agreements. '
              'We may disclose data if required by law, court order or government authority.',
        ),
        const PublicSection(
          title: '5. Data Retention',
          body: 'We retain your account information for as long as your account is active. '
              'Payment transaction records are retained for a minimum of 7 years '
              'as required by applicable financial regulations. '
              'You may request deletion of your account by contacting us — '
              'note that payment records required by law cannot be deleted.',
        ),
        const PublicSection(
          title: '6. Cookies and Local Storage',
          body: 'Our web platform uses browser local storage to remember your preferences '
              '(language, dark mode, recent locations) between sessions. '
              'We use Firebase Analytics cookies for usage analytics. '
              'You can clear this data through your browser settings.',
        ),
        const PublicSection(
          title: '7. Security',
          body: 'We implement industry-standard security measures including:\n\n'
              '• HTTPS encryption for all data in transit\n'
              '• Firebase Authentication for secure account management\n'
              '• Server-side payment hash verification (PayU SALT never in client code)\n'
              '• Firebase ID token verification on all authenticated API requests\n'
              '• Rate limiting on authentication and payment endpoints',
        ),
        const PublicSection(
          title: '8. Your Rights',
          body: 'You have the right to:\n\n'
              '• Access the personal data we hold about you\n'
              '• Correct inaccurate personal data\n'
              '• Request deletion of your personal data (subject to legal requirements)\n'
              '• Object to processing of your personal data for marketing purposes\n\n'
              'To exercise these rights, contact us through the Contact Us page.',
        ),
        const PublicSection(
          title: '9. Children\'s Privacy',
          body: 'The KrishiMithra platform is not intended for children under 18 years of age. '
              'We do not knowingly collect personal information from children. '
              'If you believe a child has provided us with personal information, '
              'please contact us immediately.',
        ),
        const PublicSection(
          title: '10. Changes to This Policy',
          body: 'We may update this Privacy Policy from time to time. Changes will be '
              'posted on this page with an updated date. Your continued use of the '
              'platform after changes are posted constitutes acceptance.',
        ),
        const PublicSection(
          title: '11. Contact',
          body: 'For privacy-related queries, please contact us at the details provided '
              'on our Contact Us page.',
        ),
      ],
    );
  }
}
