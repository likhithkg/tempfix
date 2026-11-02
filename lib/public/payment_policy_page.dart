import 'package:flutter/material.dart';
import '_public_scaffold.dart';

class PaymentPolicyPage extends StatelessWidget {
  const PaymentPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Payment Policy',
      child: _PaymentPolicyContent(),
    );
  }
}

class _PaymentPolicyContent extends StatelessWidget {
  const _PaymentPolicyContent();

  @override
  Widget build(BuildContext context) {
    return const PublicBody(
      sections: [
        PublicSection(
          title: 'Payment Policy',
          body: 'Last updated: November 2026\n\n'
              'This Payment Policy explains how payments are processed on the '
              'KrishiMithra platform, including accepted methods, pricing, '
              'confirmation, failure handling, and premium entitlement activation.',
        ),
        PublicSection(
          title: '1. Payment Gateway',
          body: 'All payments on KrishiMithra are processed through PayU India '
              '(PayU Payments Private Limited), a payment gateway authorised and '
              'regulated by the Reserve Bank of India (RBI).\n\n'
              'KrishiMithra does not process card transactions directly. All payment '
              'card details, UPI credentials, and net banking credentials are handled '
              'exclusively by PayU on its secure, PCI-DSS certified infrastructure. '
              'KrishiMithra never receives, stores, or has access to your card number, '
              'CVV, UPI PIN, or net banking password.',
        ),
        PublicSection(
          title: '2. Accepted Payment Methods',
          body: 'The following payment methods are supported via PayU (subject to '
              'PayU availability and your bank\'s terms):\n\n'
              '• UPI (Unified Payments Interface) — PhonePe, Google Pay, Paytm, '
              'BHIM, and all UPI-enabled apps\n'
              '• Debit cards — Visa, Mastercard, RuPay\n'
              '• Credit cards — Visa, Mastercard\n'
              '• Net banking — all major Indian banks\n'
              '• Digital wallets — PayU wallet and supported third-party wallets\n\n'
              'All payments are in Indian Rupees (INR) only.',
        ),
        PublicSection(
          title: '3. Pricing',
          body: 'KrishiMithra charges a one-time fee for premium feature access. '
              'The current pricing is:\n\n'
              '• 1 Premium Feature: ₹99\n'
              '  (RentHub Premium, Plant Vendor Premium, or Crop Disease AI — choose any one)\n\n'
              '• 2 Premium Features: ₹169\n'
              '  (Choose any two of the three premium features)\n\n'
              '• 3 Premium Features (All Features): ₹229\n'
              '  (RentHub Premium + Plant Vendor Premium + Crop Disease AI)\n\n'
              'Upgrade pricing: If you already own 1 feature and wish to add a second, '
              'you pay only the difference (₹169 − ₹99 = ₹70). You are never charged '
              'for features you already own.',
        ),
        PublicSection(
          title: '4. One-Time Payment Model',
          body: 'All KrishiMithra premium features are sold as one-time, permanent '
              'entitlements. There are no:\n\n'
              '• Monthly or annual subscriptions\n'
              '• Recurring charges\n'
              '• Renewal fees\n'
              '• Expiry dates on purchased features\n\n'
              'You pay once and retain permanent access to the features you have purchased.',
        ),
        PublicSection(
          title: '5. Payment Confirmation',
          body: 'After completing a payment through PayU, our backend server independently '
              'verifies the transaction status directly with PayU\'s servers using a '
              'server-side hash verification process.\n\n'
              'Premium access is granted only after server-side confirmation of a '
              'successful payment status. The browser redirect alone is never used to '
              'grant access. This protects users from fraudulent status manipulation.\n\n'
              'Upon successful verification, your premium entitlement is activated '
              'immediately and permanently. You will see your updated premium status '
              'on your Profile page under "Premium Features".',
        ),
        PublicSection(
          title: '6. Transaction Failures',
          body: 'If a payment fails — due to insufficient funds, a declined card, '
              'a connection timeout, or any other reason — no charge is made to your '
              'account. The transaction is marked as failed and no premium access is '
              'granted.\n\n'
              'You may re-attempt the payment at any time from the Premium screen '
              'inside the KrishiMithra application.\n\n'
              'If your account was debited but our system shows the payment as failed, '
              'please contact us with your transaction reference number. Banks typically '
              'reverse such charges automatically within 5–7 business days.',
        ),
        PublicSection(
          title: '7. Pending Transactions',
          body: 'Some payment methods — particularly certain UPI flows and net banking '
              'transactions — may result in a pending status. Premium access is NOT '
              'granted for pending transactions.\n\n'
              'Pending transactions are typically resolved by PayU within 24–48 hours. '
              'If a pending transaction is confirmed as successful, premium access is '
              'activated automatically. If the transaction is ultimately declined, '
              'no charge is made.\n\n'
              'If your payment remains pending for more than 48 hours, please contact '
              'us at krishimithra06@gmail.com with your transaction reference number.',
        ),
        PublicSection(
          title: '8. Duplicate Transactions',
          body: 'If you are charged twice for the same feature due to a technical error, '
              'please contact us at krishimithra06@gmail.com within 7 days with both '
              'transaction reference numbers. Duplicate charges are fully refundable. '
              'See our Refund and Cancellation Policy for the refund procedure.',
        ),
        PublicSection(
          title: '9. Payment Security',
          body: 'KrishiMithra implements the following security measures for all '
              'payment transactions:\n\n'
              '• PayU SALT (transaction signing key) is stored only on our backend '
              'server and is never included in client-side application code\n'
              '• All payment hash generation is performed server-side\n'
              '• All payment callback verification is performed server-side\n'
              '• HTTPS encryption is enforced for all data in transit\n'
              '• Firebase ID token authentication is required before initiating payment',
        ),
        PublicSection(
          title: '10. Payment Support',
          body: 'For any payment-related queries, failed transactions, refund requests, '
              'or billing disputes, please contact:\n\n'
              'Email: krishimithra06@gmail.com\n'
              'Support Hours: Monday to Saturday, 9:00 AM – 6:00 PM IST\n\n'
              'Please include your transaction reference number (txnid) in all '
              'payment-related communications.\n\n'
              'For gateway-level disputes, you may also contact PayU support at '
              'payusupport@payu.in.',
        ),
        PublicSection(
          title: '11. Refunds',
          body: 'For refund eligibility conditions and the refund request procedure, '
              'please refer to our Refund and Cancellation Policy.',
        ),
      ],
    );
  }
}
