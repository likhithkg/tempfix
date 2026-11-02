import 'package:flutter/material.dart';
import '_public_scaffold.dart';

class DigitalFulfillmentPage extends StatelessWidget {
  const DigitalFulfillmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Digital Service Fulfilment Policy',
      child: _DigitalFulfillmentContent(),
    );
  }
}

class _DigitalFulfillmentContent extends StatelessWidget {
  const _DigitalFulfillmentContent();

  @override
  Widget build(BuildContext context) {
    return const PublicBody(
      sections: [
        PublicSection(
          title: 'Digital Service Fulfilment Policy',
          body: 'Last updated: November 2026\n\n'
              'This policy describes how KrishiMithra delivers its premium digital '
              'services to users following a successful payment. Because all premium '
              'features are digital services, there is no physical delivery, no courier, '
              'and no waiting period.',
        ),
        PublicSection(
          title: '1. Nature of the Service',
          body: 'KrishiMithra sells digital feature entitlements — specifically, '
              'permanent access to one or more of the following premium features:\n\n'
              '• RentHub Premium: Ability to publish new farm equipment rental listings\n'
              '• Plant Vendor Premium: Ability to list plants and nursery products for sale\n'
              '• Crop Disease AI: Access to AI-powered crop disease detection\n\n'
              'These are intangible digital services delivered through the KrishiMithra '
              'web and mobile application. There is no physical product, no shipping, '
              'no download file, and no manual configuration required.',
        ),
        PublicSection(
          title: '2. When Access Is Activated',
          body: 'Premium feature access is activated immediately and automatically '
              'upon successful server-side verification of your payment.\n\n'
              'Our backend server independently verifies your payment status directly '
              'with PayU\'s servers after you complete the payment flow. This process '
              'typically completes within a few seconds of a successful payment.\n\n'
              'You do not need to:\n'
              '• Wait for a confirmation email\n'
              '• Contact support to activate access\n'
              '• Restart the application\n'
              '• Log out and log back in\n\n'
              'In most cases, your premium features are available the moment you are '
              'returned to the KrishiMithra application after completing payment.',
        ),
        PublicSection(
          title: '3. How to Access Purchased Features',
          body: 'After your payment is verified and your entitlement is activated:\n\n'
              '1. Your Profile page (accessible from the app\'s bottom navigation bar) '
              'will show your purchased features under "Premium Features".\n\n'
              '2. The premium features you purchased will be unlocked within the app:\n'
              '   • RentHub Premium: The "List Your Machine" option will become available\n'
              '   • Plant Vendor Premium: The "List Your Plants" option will become available\n'
              '   • Crop Disease AI: Full access to the crop disease detection screen\n\n'
              '3. Your entitlement is permanent — it will remain active across all '
              'future sessions, on both the web app and Android app, as long as you '
              'use the same account.',
        ),
        PublicSection(
          title: '4. Pending or Unsuccessful Payments',
          body: 'If your payment is pending or unsuccessful:\n\n'
              'Pending: Some UPI and net banking transactions may be placed in a '
              'pending state by your bank. Premium access is NOT activated for pending '
              'transactions. Access is activated only after the payment is confirmed '
              'as successful. Pending transactions typically resolve within 24–48 hours.\n\n'
              'Failed: If your payment fails, no charge is made and no access is '
              'granted. You may re-attempt the payment from the Premium screen.\n\n'
              'Cancelled: If you exit the payment flow without completing it, no charge '
              'is made and no access is granted.\n\n'
              'If you believe your payment was successful but your feature is not '
              'activated after 24 hours, please contact us with your transaction '
              'reference number (txnid).',
        ),
        PublicSection(
          title: '5. Verification of Your Entitlement',
          body: 'You can verify your premium entitlements at any time:\n\n'
              '• Log into KrishiMithra\n'
              '• Navigate to your Profile (bottom navigation bar)\n'
              '• Look for the "Premium Features" section\n'
              '• Your owned features will be listed with a verified checkmark\n\n'
              'Your payment history is also accessible from the same Profile page '
              'under "Payment History".',
        ),
        PublicSection(
          title: '6. Access Across Devices',
          body: 'Your premium entitlement is tied to your KrishiMithra account, '
              'not to a specific device or browser. You may:\n\n'
              '• Use your premium features on any device where you log into your account\n'
              '• Switch between the web app and Android app freely\n'
              '• Access your features after changing your device\n\n'
              'Entitlements are stored server-side and are never lost due to '
              'reinstalling the app, clearing browser cache, or changing devices.',
        ),
        PublicSection(
          title: '7. Service Availability',
          body: 'KrishiMithra\'s services are hosted on cloud infrastructure and are '
              'intended to be available 24 hours a day, 7 days a week. However, '
              'brief interruptions may occur during maintenance or due to third-party '
              'service issues.\n\n'
              'During any temporary outage, your premium entitlements remain intact '
              'and will be accessible as soon as the service is restored.',
        ),
        PublicSection(
          title: '8. Support for Fulfilment Issues',
          body: 'If you experience any issue accessing a premium feature after a '
              'successful payment, please contact us:\n\n'
              'Email: krishimithra06@gmail.com\n'
              'Support Hours: Monday to Saturday, 9:00 AM – 6:00 PM IST\n\n'
              'Please provide:\n'
              '• Your registered email address or phone number\n'
              '• The transaction reference number (txnid)\n'
              '• The name of the feature you purchased\n'
              '• A description of the issue you are experiencing\n\n'
              'We commit to resolving all fulfilment issues within 1 business day.',
        ),
        PublicSection(
          title: '9. No Physical Delivery',
          body: 'KrishiMithra does not ship any physical goods. There are no:\n\n'
              '• Physical products or packages\n'
              '• Delivery timelines\n'
              '• Tracking numbers or logistics partners\n'
              '• Customs, duties, or shipping fees\n\n'
              'All services are delivered digitally through the KrishiMithra application '
              'upon successful payment verification.',
        ),
      ],
    );
  }
}
