import 'package:flutter/material.dart';
import '../theme.dart';
import '_public_scaffold.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Frequently Asked Questions',
      child: _FAQContent(),
    );
  }
}

class _FAQContent extends StatelessWidget {
  const _FAQContent();

  static const _faqs = [
    _FAQ('What is KrishiMithra?',
        'KrishiMithra is a comprehensive digital agriculture platform built for India. '
        'It connects farmers, machine owners, plant sellers, labourers, and exporters '
        'on a single platform. Services include smart weather forecasts, equipment rental, '
        'plant marketplace, AI crop disease detection, labour hiring, export management '
        'and an AI chatbot for agricultural queries.'),
    _FAQ('Is KrishiMithra free to use?',
        'Most features of KrishiMithra are completely free: weather, browsing markets, '
        'exporter hub, labour hub browsing, chatbot, booking machines, and more.\n\n'
        'Three advanced features require a one-time premium payment:\n'
        '• RentHub (for listing new machines)\n'
        '• Plant Vendor (for listing plants)\n'
        '• Crop Disease AI'),
    _FAQ('What does "one-time payment" mean?',
        'You pay once and get permanent access forever — there is no subscription, '
        'no renewal charge, and no expiry date. Pay once, use it for life.'),
    _FAQ('What are the premium prices?',
        '• 1 Feature: ₹99\n'
        '• Any 2 Features: ₹169\n'
        '• All 3 Features: ₹229\n\n'
        'If you already own one feature and want to add more, you pay only the '
        'difference. You will never be charged for features you already own.'),
    _FAQ('How do I pay?',
        'Payments are processed through PayU, a trusted Indian payment gateway. '
        'You can pay using UPI, debit/credit card, net banking, or digital wallets. '
        'Your payment card details are handled exclusively by PayU — KrishiMithra '
        'never receives or stores your card information.'),
    _FAQ('I paid but my premium feature is not activated. What should I do?',
        'Premium features are activated automatically within a few minutes of a '
        'successful payment. If your feature is not activated:\n\n'
        '1. Go to your Profile page and check "Premium Features"\n'
        '2. Wait 5 minutes and refresh the app\n'
        '3. If still not activated, note your transaction reference number '
        '(txnid) from your payment confirmation and contact us through the Contact page.\n\n'
        'We will resolve it within 1 business day.'),
    _FAQ('Do I need RentHub Premium to browse or book machines?',
        'No. Browsing machine listings, searching, viewing details, contacting '
        'machine owners and booking machines is completely free. '
        'RentHub Premium is required ONLY when you want to PUBLISH a new machine listing '
        'as a machine owner.'),
    _FAQ('Can I use KrishiMithra on a web browser?',
        'Yes. KrishiMithra is available as a web application at krishimithra.web.app '
        'and also as an Android mobile application. Most features work on both.'),
    _FAQ('Which languages are supported?',
        'KrishiMithra supports English, Hindi, Kannada, Tamil, Telugu, Marathi, '
        'and Malayalam. You can change your language from the Profile page.'),
    _FAQ('How is my payment verified?',
        'All payment verification is done server-side. When you complete a payment, '
        'our backend securely contacts PayU\'s servers to confirm the transaction status '
        'before granting premium access. We never grant access based on the browser '
        'redirect alone.'),
    _FAQ('Can I get a refund?',
        'Refunds are available in specific circumstances — primarily if a technical error '
        'caused a charge without activating your feature. Please see our full '
        'Refund and Cancellation Policy for details. Refund requests must be made '
        'within 7 days of the transaction.'),
    _FAQ('How do I contact support?',
        'Visit our Contact Us page for support contact details including email and phone. '
        'For payment-specific issues, please have your transaction reference number ready.'),
    _FAQ('Is my data safe?',
        'Yes. We use industry-standard security practices including HTTPS encryption, '
        'Firebase Authentication, and server-side token verification. '
        'We do not sell your personal data to third parties. '
        'Please read our Privacy Policy for full details.'),
    _FAQ('What is PayU?',
        'PayU is one of India\'s largest and most trusted payment gateways, authorised '
        'by the Reserve Bank of India (RBI). It supports UPI, cards, net banking '
        'and wallets. KrishiMithra uses PayU for all payment processing.'),
  ];

  @override
  Widget build(BuildContext context) {
    return PublicBody(
      sections: [
        const PublicSection(
          title: 'Frequently Asked Questions',
          body: 'Find answers to the most common questions about KrishiMithra.',
        ),
        PublicSection(
          title: '',
          customContent: Column(
            children: _faqs.map((f) => _FAQItem(f)).toList(),
          ),
        ),
      ],
    );
  }
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ(this.question, this.answer);
}

class _FAQItem extends StatefulWidget {
  final _FAQ faq;
  // ignore: prefer_const_constructors_in_immutables
  _FAQItem(this.faq) : super(key: ValueKey(faq.question));

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _open ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _open
              ? KMColors.primary.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.faq.question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _open ? KMColors.primaryDark : KMColors.textPrimary,
            ),
          ),
          trailing: Icon(
            _open ? Icons.remove_rounded : Icons.add_rounded,
            color: KMColors.primary,
            size: 20,
          ),
          onExpansionChanged: (v) => setState(() => _open = v),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.faq.answer,
                style: const TextStyle(
                    fontSize: 13,
                    color: KMColors.textSecondary,
                    height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
