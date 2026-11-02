import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared scaffold used by all public/legal pages.
class PublicScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const PublicScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: KMColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            child,
            const PublicFooter(),
          ],
        ),
      ),
    );
  }
}

/// Container with a responsive max-width for legal page content.
class PublicBody extends StatelessWidget {
  final List<Widget> sections;

  const PublicBody({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isWide ? 40 : 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections,
          ),
        ),
      ),
    );
  }
}

/// A single section with title + body text on a legal page.
class PublicSection extends StatelessWidget {
  final String title;
  final String body;
  final Widget? customContent;

  const PublicSection({
    super.key,
    required this.title,
    this.body = '',
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: KMColors.textPrimary)),
          const SizedBox(height: 10),
          if (body.isNotEmpty)
            Text(body,
                style: const TextStyle(
                    fontSize: 14,
                    color: KMColors.textSecondary,
                    height: 1.75)),
          if (customContent != null) customContent!,
        ],
      ),
    );
  }
}

/// Shared footer shown at the bottom of every public/legal page.
class PublicFooter extends StatelessWidget {
  const PublicFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _footerLink(context, 'About Us', '/about'),
              _footerLink(context, 'Products & Services', '/services'),
              _footerLink(context, 'Pricing', '/pricing'),
              _footerLink(context, 'Contact Us', '/contact'),
              _footerLink(context, 'Terms & Conditions', '/terms'),
              _footerLink(context, 'Privacy Policy', '/privacy'),
              _footerLink(context, 'Refund & Cancellation', '/refund'),
              _footerLink(context, 'Payment Policy', '/payment-policy'),
              _footerLink(context, 'Digital Fulfilment', '/digital-fulfillment'),
              _footerLink(context, 'FAQ', '/faq'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '© 2026 KrishiMithra Private Limited. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(BuildContext context, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Text(label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withValues(alpha: 0.2))),
    );
  }
}

/// A highlighted notice box used for important information.
class PublicNotice extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const PublicNotice({
    super.key,
    required this.text,
    this.color = const Color(0xFFFFF3E0),
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}
