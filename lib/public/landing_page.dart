import 'package:flutter/material.dart';

import '../theme.dart';
import '../config/km_images.dart';
import '_public_scaffold.dart' show PublicFooter;

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KMColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: KMColors.primaryDark,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                Image.asset(KMImages.logo, width: 32, height: 32,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.eco_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 10),
                const Text('KrishiMithra',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.white)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: KMColors.primaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Get Started',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _HeroSection()),
          SliverToBoxAdapter(child: _ServicesSection()),
          SliverToBoxAdapter(child: _PremiumSection()),
          SliverToBoxAdapter(child: _AboutSection()),
          const SliverToBoxAdapter(child: PublicFooter()),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [KMColors.primaryDark, KMColors.primary, Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: isWide ? 72 : 48),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _HeroText()),
                const SizedBox(width: 40),
                Expanded(child: _HeroImage()),
              ],
            )
          : Column(children: [_HeroText(), const SizedBox(height: 32), _HeroImage()]),
    );
  }
}

class _HeroText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: const Text('India\'s Smart Agriculture Platform',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(height: 18),
        const Text(
          'Empowering\nFarmers with\nDigital Tools',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'KrishiMithra connects farmers, exporters, labourers and vendors '
          'on a single digital platform. Access crop disease detection, '
          'equipment rental, export services, labour hiring and more.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              height: 1.6),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: KMColors.primaryDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: const Text('Get Started Free',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/pricing'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('View Pricing',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          KMImages.loginBg,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.agriculture_rounded,
                    size: 80, color: Colors.white70),
                const SizedBox(height: 12),
                Text('Agriculture Made Smart',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  static const _services = [
    _Service(Icons.cloud_rounded, 'Smart Weather', KMColors.primary,
        'Hyper-local forecasts, irrigation guidance, disease risk alerts'),
    _Service(Icons.agriculture_rounded, 'RentHub', Color(0xFFE65100),
        'Rent or list farm equipment — tractors, harvesters, rotavators'),
    _Service(Icons.local_florist_rounded, 'Plant Vendor', Color(0xFF2E7D32),
        'Buy and sell plants, seeds, saplings and nursery products'),
    _Service(Icons.biotech_rounded, 'Crop Disease AI', Color(0xFF1565C0),
        'AI-powered crop disease detection with treatment guidance'),
    _Service(Icons.people_rounded, 'Labour Hub', Color(0xFF6A1B9A),
        'Hire skilled agricultural workers; find local farm employment'),
    _Service(Icons.local_shipping_rounded, 'Exporter Hub', Color(0xFF00695C),
        'Connect farmers with exporters; manage purchase orders'),
    _Service(Icons.storefront_rounded, 'GreenBazaar', Color(0xFF558B2F),
        'Farm-to-buyer marketplace for fresh produce'),
    _Service(Icons.smart_toy_rounded, 'AI Chatbot', KMColors.primaryDark,
        'Ask agricultural questions in your language; get instant advice'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 20, vertical: 60),
      color: const Color(0xFFF8FAF8),
      child: Column(
        children: [
          const Text('Everything a Farmer Needs',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: KMColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'One platform — multiple services designed for Indian agriculture',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: KMColors.textSecondary),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isWide ? 1.1 : 0.95,
            ),
            itemCount: _services.length,
            itemBuilder: (_, i) => _ServiceCard(_services[i]),
          ),
        ],
      ),
    );
  }
}

class _Service {
  final IconData icon;
  final String name;
  final Color color;
  final String description;
  const _Service(this.icon, this.name, this.color, this.description);
}

class _ServiceCard extends StatelessWidget {
  final _Service service;
  const _ServiceCard(this.service);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: service.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(service.icon, color: service.color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(service.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: KMColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            service.description,
            style: const TextStyle(
                fontSize: 11,
                color: KMColors.textSecondary,
                height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text('Premium Features',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'One-time payment · Permanent access · No subscriptions',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: const [
              _PremiumCard('₹99', '1 Feature', '• RentHub OR\n• Plant Vendor OR\n• Crop Disease AI', false),
              _PremiumCard('₹169', '2 Features', '• Any two features\n• Best value for most', false),
              _PremiumCard('₹229', '3 Features', '• All three features\n• Full premium access', true),
            ],
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/pricing'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('View full pricing details →',
                style: TextStyle(
                    fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final String price, title, features;
  final bool highlight;
  const _PremiumCard(this.price, this.title, this.features, this.highlight);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? Colors.white : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: highlight
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(price,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: highlight ? KMColors.primaryDark : Colors.white)),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: highlight ? KMColors.primary : Colors.white70)),
          const SizedBox(height: 12),
          Text(features,
              style: TextStyle(
                  fontSize: 12,
                  height: 1.8,
                  color: highlight ? KMColors.textSecondary : Colors.white70)),
          const SizedBox(height: 16),
          Text('One-time · Permanent',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlight ? Colors.green : Colors.white60)),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 60),
      color: Colors.white,
      child: Column(
        children: [
          const Text('Why KrishiMithra?',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: KMColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Built for the needs of Indian farmers',
            style: TextStyle(fontSize: 15, color: KMColors.textSecondary),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureBullet(Icons.language_rounded, 'Multi-Language',
                  'Available in English, Hindi, Kannada, Tamil, Telugu, Marathi, Malayalam'),
              _FeatureBullet(Icons.security_rounded, 'Secure Payments',
                  'PayU-powered payments with server-side hash verification'),
              _FeatureBullet(Icons.smartphone_rounded, 'Mobile & Web',
                  'Works on Android app and any web browser'),
              _FeatureBullet(Icons.cloud_done_rounded, 'Always Available',
                  'Cloud-hosted services available 24/7'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String title, description;
  const _FeatureBullet(this.icon, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KMColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: KMColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12,
                        color: KMColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
