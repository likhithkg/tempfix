import 'package:flutter/material.dart';
import '../theme.dart';
import '_public_scaffold.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const _email        = 'krishimithra06@gmail.com';
  static const _address      = 'Khata 103, Kolaghatta, Anekere Post,\n'
                               'Turuvekere Taluk, Tumkur District,\n'
                               'Karnataka, India — 572212';
  static const _supportHours = 'Monday to Saturday, 9:00 AM – 6:00 PM IST';

  @override
  Widget build(BuildContext context) {
    return const PublicScaffold(
      title: 'Contact Us',
      child: _ContactContent(),
    );
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent();

  @override
  Widget build(BuildContext context) {
    return PublicBody(
      sections: [
        const PublicSection(
          title: 'Contact KrishiMithra',
          body: 'We are here to help. For support queries, payment issues, '
              'account problems, or general enquiries, please contact us using '
              'the details below.',
        ),
        PublicSection(
          title: 'Customer Support',
          customContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ContactRow(Icons.email_outlined, 'Email', ContactPage._email),
              const SizedBox(height: 12),
              const _ContactRow(Icons.access_time_rounded, 'Support Hours', ContactPage._supportHours),
            ],
          ),
        ),
        PublicSection(
          title: 'Registered Office',
          customContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KrishiMithra Private Limited',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KMColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const _ContactRow(Icons.location_on_outlined, 'Address', ContactPage._address),
            ],
          ),
        ),
        const PublicSection(
          title: 'Payment Support',
          body: 'For queries related to payments made through KrishiMithra — '
              'including failed transactions, refund status, or billing disputes — '
              'please email us at krishimithra06@gmail.com with your transaction '
              'reference number (txnid) as shown in your payment confirmation.\n\n'
              'For gateway-level issues, PayU customer support may also be reached '
              'at payusupport@payu.in.',
        ),
        const PublicSection(
          title: 'Response Time',
          body: 'We aim to respond to all support queries within 2 business days. '
              'Payment-related disputes are prioritised and typically handled within '
              '1 business day.',
        ),
        const PublicSection(
          title: 'Grievance Officer',
          body: 'In accordance with the Information Technology Act 2000 and applicable '
              'consumer protection regulations, any grievances related to the platform '
              'or its services may be addressed to our Grievance Officer:\n\n'
              'Name: Likhith K G\n'
              'Designation: Founder and CEO\n'
              'Email: krishimithra06@gmail.com\n'
              'Address: Khata 103, Kolaghatta, Anekere Post, Turuvekere Taluk, '
              'Tumkur District, Karnataka, India — 572212',
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: KMColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: KMColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: KMColors.textPrimary, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
