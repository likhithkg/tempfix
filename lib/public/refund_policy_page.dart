import 'package:flutter/material.dart';
import '_public_scaffold.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Refund and Cancellation Policy',
      child: _RefundContent(),
    );
  }
}

class _RefundContent extends StatelessWidget {
  const _RefundContent();

  @override
  Widget build(BuildContext context) {
    return PublicBody(
      sections: [
        const PublicSection(
          title: 'Refund and Cancellation Policy',
          body: 'Last updated: 2024\n\n'
              'This policy explains the terms under which refunds may be considered '
              'for payments made on the KrishiMithra platform.',
        ),
        PublicSection(
          title: 'Nature of Services',
          customContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KrishiMithra sells digital service entitlements — specifically, '
                'permanent access to premium features on the platform. '
                'These are intangible digital services delivered immediately '
                'upon successful payment verification.',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6A6A),
                    height: 1.75),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_rounded, color: Color(0xFF2E7D32), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Premium feature access is activated immediately and permanently '
                        'upon successful payment verification.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PublicSection(
          title: 'Refund Eligibility',
          body: 'Refunds may be considered only in the following circumstances:\n\n'
              '1. Technical failure: If a payment was deducted from your account '
              'but the premium feature was not activated within 24 hours due to a '
              'system error on our side.\n\n'
              '2. Duplicate charge: If the same feature was charged more than once '
              'due to a technical error.\n\n'
              '3. Unauthorised transaction: If you believe a payment was made '
              'from your account without your authorisation.\n\n'
              'Refund requests must be made within 7 days of the transaction date.',
        ),
        const PublicSection(
          title: 'Non-Refundable Situations',
          body: 'Refunds will NOT be granted in the following situations:\n\n'
              '• You changed your mind after purchasing a premium feature\n'
              '• You no longer wish to use the platform\n'
              '• You purchased a feature without reading the feature description\n'
              '• You accidentally purchased a feature (user error)\n'
              '• A payment was cancelled by you during the payment process '
              '(no charge occurs in this case)\n'
              '• A feature was used before the refund request was made\n'
              '• More than 7 days have passed since the transaction',
        ),
        const PublicSection(
          title: 'Failed and Cancelled Payments',
          body: 'If your payment fails or you cancel the payment process, '
              'no charge is made to your account. The transaction is marked as failed '
              'or cancelled and no premium access is granted. '
              'You may attempt the payment again at any time.',
        ),
        const PublicSection(
          title: 'Pending Payments',
          body: 'Some payment methods may result in a pending transaction status. '
              'Premium access is granted only after the payment is confirmed as successful '
              'by PayU. Pending transactions are typically resolved within 24 hours. '
              'If your payment remains pending beyond 24 hours, please contact us.',
        ),
        const PublicSection(
          title: 'How to Request a Refund',
          body: 'To request a refund, please contact us through the Contact Us page with:\n\n'
              '• Your registered email address or phone number\n'
              '• The transaction reference number (txnid)\n'
              '• The date and amount of the transaction\n'
              '• The reason for the refund request\n\n'
              'We will review your request and respond within 5 business days. '
              'Approved refunds are processed within 7–10 business days and '
              'credited to the original payment method.',
        ),
        const PublicSection(
          title: 'Payment Gateway Disputes',
          body: 'If you believe a payment was incorrectly processed or you have been '
              'incorrectly charged, you may also raise a dispute directly with PayU '
              'or your bank. We will cooperate fully with any legitimate dispute process.',
        ),
        const PublicSection(
          title: 'Service Fulfilment',
          body: 'Premium features are digital services delivered immediately upon '
              'payment verification. There is no physical delivery involved. '
              'Access to premium features is permanent and does not expire.\n\n'
              'If you face any technical issue accessing a premium feature you have paid for, '
              'please contact us immediately and we will resolve it within 1 business day.',
        ),
      ],
    );
  }
}
